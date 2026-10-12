require "rails_helper"

RSpec.describe Appeals::Resolver do
  let(:user) { create(:user) }
  let(:admin) { create(:user, :super_admin) }
  let(:article) { create(:article, user: user, automod_label: "clear_and_obvious_spam") }
  let(:appeal) { create(:flag_appeal, user: user, appealable: article) }

  let(:mascot) { create(:user) }

  describe ".approve" do
    before do
      allow(Settings::General).to receive(:mascot_user_id).and_return(mascot.id)
      user.add_role(:suspended)
      user.add_role(:spam)
      Reaction.create!(user_id: mascot.id, reactable: article, category: "vomit")
    end

    it "removes suspended/spam roles from user and clears article automod_label" do
      expect(user.spam_or_suspended?).to be true

      described_class.approve(appeal: appeal, admin: admin)

      user.reload
      article.reload
      appeal.reload

      expect(user.spam_or_suspended?).to be false
      expect(article.automod_label).to eq("no_moderation_label")
      expect(appeal.status).to eq("approved")
      expect(appeal.resolved_by).to eq(admin)
      expect(Reaction.exists?(user_id: mascot.id, reactable: article, category: "vomit")).to be false
    end

    it "approves appeal when appealable target is a User profile" do
      user_appeal = create(:flag_appeal, user: user, appealable: user)
      described_class.approve(appeal: user_appeal, admin: admin)

      user.reload
      user_appeal.reload

      expect(user.spam_or_suspended?).to be false
      expect(user_appeal.status).to eq("approved")
    end

    it "approves appeal when appealable target is a Comment and cleans up vomit reactions" do
      comment = create(:comment, user: user, score: -196)
      Reaction.create!(user_id: mascot.id, reactable: comment, category: "vomit")
      comment_appeal = create(:flag_appeal, user: user, appealable: comment)
      allow(Comments::CalculateScoreWorker).to receive(:perform_async)

      described_class.approve(appeal: comment_appeal, admin: admin)

      comment_appeal.reload

      expect(comment_appeal.status).to eq("approved")
      expect(Reaction.exists?(user_id: mascot.id, reactable: comment, category: "vomit")).to be false
      expect(Comments::CalculateScoreWorker).to have_received(:perform_async).with(comment.id)
    end

    context "with the author's wider flagged history" do
      let(:other_flagged) { create(:article, user: user, automod_label: "likely_spam") }
      let!(:high_quality) { create(:article, user: user, automod_label: "great_and_on_topic") }

      before do
        allow(Articles::BustMultipleCachesWorker).to receive(:perform_async)
        allow(Users::BustCacheWorker).to receive(:perform_async)
        Reaction.create!(user_id: mascot.id, reactable: other_flagged, category: "vomit")
        Reaction.create!(user_id: mascot.id, reactable: user, category: "vomit")
      end

      it "resets flagged labels on all of the author's articles but spares high quality ones" do
        described_class.approve(appeal: appeal, admin: admin)

        expect(other_flagged.reload.automod_label).to eq("no_moderation_label")
        expect(high_quality.reload.automod_label).to eq("great_and_on_topic")
      end

      it "destroys mascot vomit on the author's other articles and profile" do
        described_class.approve(appeal: appeal, admin: admin)

        expect(Reaction.where(user_id: mascot.id, category: "vomit")).to be_empty
      end

      it "keeps vomit reactions from moderators" do
        human_vomit = create(:vomit_reaction, reactable: other_flagged)

        described_class.approve(appeal: appeal, admin: admin)

        expect(Reaction.exists?(human_vomit.id)).to be true
      end

      it "does not touch other users' articles or reactions" do
        bystander_article = create(:article, user: create(:user), automod_label: "clear_and_obvious_spam")
        Reaction.create!(user_id: mascot.id, reactable: bystander_article, category: "vomit")

        described_class.approve(appeal: appeal, admin: admin)

        expect(bystander_article.reload.automod_label).to eq("clear_and_obvious_spam")
        expect(Reaction.exists?(user_id: mascot.id, reactable: bystander_article, category: "vomit")).to be true
      end

      it "purges the edge cache for the profile and the articles whose labels were reset" do
        described_class.approve(appeal: appeal, admin: admin)

        expect(Users::BustCacheWorker).to have_received(:perform_async).with(user.id)
        expect(Articles::BustMultipleCachesWorker).to have_received(:perform_async)
          .with(array_including(article.id, other_flagged.id))
      end
    end

    it "stops the author from being treated as a repeat auto-flagged offender" do
      create_list(:article, 3, user: user, automod_label: "clear_and_obvious_spam").each do |flagged|
        Reaction.create!(user_id: mascot.id, reactable: flagged, category: "vomit")
      end
      expect(Spam::Handler.__send__(:repeat_auto_flagged_author?, user: user)).to be true

      described_class.approve(appeal: appeal, admin: admin)

      expect(Spam::Handler.__send__(:repeat_auto_flagged_author?, user: user.reload)).to be false
    end

    it "is idempotent: a second approval returns false and does not re-run side effects" do
      allow(Articles::ScoreCalcWorker).to receive(:perform_async)
      expect(described_class.approve(appeal: appeal, admin: admin)).to be true

      user.add_role(:suspended)
      replay = FlagAppeal.find(appeal.id)

      expect(described_class.approve(appeal: replay, admin: admin)).to be false
      expect(user.reload.suspended?).to be true
      expect(Articles::ScoreCalcWorker).to have_received(:perform_async).once
    end

    it "does not re-approve an appeal that was already rejected" do
      described_class.reject(appeal: appeal, admin: admin)

      expect(described_class.approve(appeal: FlagAppeal.find(appeal.id), admin: admin)).to be false
      expect(appeal.reload.status).to eq("rejected")
      expect(user.reload.spam_or_suspended?).to be true
    end

    it "recalculates the scores of all the author's content once the restriction is lifted" do
      other_article = create(:article, user: user)
      comment = create(:comment, user: user)
      allow(Articles::ScoreCalcWorker).to receive(:perform_async)
      allow(Comments::CalculateScoreWorker).to receive(:perform_async)

      described_class.approve(appeal: appeal, admin: admin)

      # The spam role took 500 points off every one of these, and nothing else would restore them.
      expect(Articles::ScoreCalcWorker).to have_received(:perform_async).with(article.id)
      expect(Articles::ScoreCalcWorker).to have_received(:perform_async).with(other_article.id)
      expect(Comments::CalculateScoreWorker).to have_received(:perform_async).with(comment.id)
    end

    it "only recalculates the appealed content when the author was not restricted" do
      user.remove_role(:suspended)
      user.remove_role(:spam)
      other_comment = create(:comment, user: user)
      comment = create(:comment, user: user)
      comment_appeal = create(:flag_appeal, user: user, appealable: comment)
      allow(Comments::CalculateScoreWorker).to receive(:perform_async)

      described_class.approve(appeal: comment_appeal, admin: admin)

      expect(Comments::CalculateScoreWorker).to have_received(:perform_async).with(comment.id)
      expect(Comments::CalculateScoreWorker).not_to have_received(:perform_async).with(other_comment.id)
    end

    it "leaves a note on the user recording who approved the appeal" do
      described_class.approve(appeal: appeal, admin: admin)

      note = Note.find_by(noteable: user, reason: "flag_appeal_approved")
      expect(note.author).to eq(admin)
      expect(note.content).to include("##{appeal.id}", admin.username)
    end

    it "still reinstates the user when the appealed content was deleted" do
      appeal_id = appeal.id
      article.delete

      expect(described_class.approve(appeal: FlagAppeal.find(appeal_id), admin: admin)).to be true
      expect(user.reload.spam_or_suspended?).to be false
    end
  end

  describe "automated approval (no admin)" do
    def automatic_block!(at:, slug: "automatic_suspended", **data)
      create(:audit_log, user_id: mascot.id, category: "spam.automatic_block", slug: slug,
                         data: { action: slug, target_user_id: user.id, reason: "test", **data }, created_at: at)
    end

    def human_note!(reason, at:)
      Note.create!(noteable: user, author: admin, reason: reason, content: "by a moderator", created_at: at)
    end

    before do
      allow(Settings::General).to receive(:mascot_user_id).and_return(mascot.id)
      user.add_role(:suspended)
    end

    it "approves when only the automation restricted the user" do
      automatic_block!(at: 1.day.ago)

      expect(described_class.auto_approvable?(appeal)).to be true
      expect(described_class.approve(appeal: appeal)).to be true
      expect(user.reload.suspended?).to be false
    end

    it "refuses when a moderator banned the user after the automation did" do
      automatic_block!(at: 2.days.ago)
      human_note!("Suspended", at: 1.day.ago)

      expect(described_class.approve(appeal: appeal)).to be false
      expect(user.reload.suspended?).to be true
      expect(appeal.reload.status).to eq("open")
    end

    it "refuses when a moderator banned the user before the automation re-flagged them" do
      human_note!("Spam", at: 2.days.ago)
      automatic_block!(at: 1.day.ago)

      expect(described_class.approve(appeal: appeal)).to be false
      expect(user.reload.suspended?).to be true
    end

    it "refuses when there is no record of an automatic block" do
      expect(described_class.approve(appeal: appeal)).to be false
      expect(user.reload.suspended?).to be true
    end

    it "ignores a manual ban from a restriction that was already lifted" do
      human_note!("Suspended", at: 3.days.ago)
      human_note!("Good standing", at: 2.days.ago)
      automatic_block!(at: 1.day.ago)

      expect(described_class.approve(appeal: appeal)).to be true
      expect(user.reload.suspended?).to be false
    end

    it "still lets an admin approve an appeal against a manual ban" do
      human_note!("Suspended", at: 1.day.ago)

      expect(described_class.approve(appeal: appeal, admin: admin)).to be true
      expect(user.reload.suspended?).to be false
    end

    it "approves users that no longer have a restriction" do
      user.remove_role(:suspended)

      expect(described_class.auto_approvable?(appeal)).to be true
    end
  end

  describe "republishing on approval" do
    before do
      allow(Settings::General).to receive(:mascot_user_id).and_return(mascot.id)
      allow(Articles::BustMultipleCachesWorker).to receive(:perform_async)
      user.add_role(:suspended)
    end

    def unpublished_article(**attrs)
      create(:article, user: user).tap { |a| a.update_columns(published: false, **attrs) }
    end

    context "when the target is an Article" do
      it "republishes it without re-running the spam checks" do
        article.update_columns(published: false)

        # update_all skips the publish callbacks that would re-run the spam checks.
        sidekiq_assert_no_enqueued_jobs(only: Articles::HandleSpamWorker) do
          described_class.approve(appeal: appeal, admin: admin)
        end

        expect(article.reload.published).to be true
        expect(Articles::BustMultipleCachesWorker).to have_received(:perform_async).with(array_including(article.id))
      end

      it "leaves a never-published draft unpublished" do
        article.update_columns(published: false, published_at: nil)

        described_class.approve(appeal: appeal, admin: admin)

        expect(article.reload.published).to be false
      end
    end

    context "when the target is the User" do
      let(:user_appeal) { create(:flag_appeal, user: user, appealable: user) }
      let!(:hidden) { unpublished_article }
      let!(:also_hidden) { unpublished_article }
      let!(:author_unpublished) { unpublished_article }
      let!(:draft) { unpublished_article(published_at: nil) }

      def suspension_log!(ids, at: 1.day.ago)
        create(:audit_log, user_id: mascot.id, category: "spam.automatic_block", slug: "automatic_suspended",
                           data: { target_user_id: user.id, unpublished_article_ids: ids }, created_at: at)
      end

      it "restores only the posts recorded by the automatic suspensions" do
        suspension_log!([hidden.id], at: 2.days.ago)
        suspension_log!([also_hidden.id, draft.id])

        sidekiq_assert_no_enqueued_jobs(only: Articles::HandleSpamWorker) do
          described_class.approve(appeal: user_appeal, admin: admin)
        end

        expect(hidden.reload.published).to be true
        expect(also_hidden.reload.published).to be true
        expect(author_unpublished.reload.published).to be false
        expect(draft.reload.published).to be false
        expect(Articles::BustMultipleCachesWorker).to have_received(:perform_async)
          .with(array_including(hidden.id, also_hidden.id))
      end

      it "ignores suspensions that an earlier approved appeal already resolved" do
        suspension_log!([author_unpublished.id], at: 3.days.ago)
        create(:flag_appeal, user: user, appealable: article, status: :approved, updated_at: 2.days.ago)
        suspension_log!([hidden.id])

        described_class.approve(appeal: user_appeal, admin: admin)

        expect(hidden.reload.published).to be true
        expect(author_unpublished.reload.published).to be false
      end

      it "republishes nothing when the suspension recorded no posts" do
        described_class.approve(appeal: user_appeal, admin: admin)

        expect(hidden.reload.published).to be false
        expect(user.reload.suspended?).to be false
      end
    end
  end

  describe ".reject" do
    it "marks the appeal as rejected" do
      expect(described_class.reject(appeal: appeal, admin: admin)).to be true

      appeal.reload
      expect(appeal.status).to eq("rejected")
      expect(appeal.resolved_by).to eq(admin)
    end

    it "does not leave a reinstatement note" do
      described_class.reject(appeal: appeal, admin: admin)

      expect(Note.where(noteable: user, reason: "flag_appeal_approved")).to be_empty
    end

    it "does not overwrite an appeal that was already approved" do
      appeal.update!(status: :approved, resolved_by: admin)

      expect(described_class.reject(appeal: FlagAppeal.find(appeal.id), admin: create(:user, :super_admin))).to be false
      expect(appeal.reload.status).to eq("approved")
      expect(appeal.resolved_by).to eq(admin)
    end

    it "leaves the user's restrictions and flagged content untouched" do
      user.add_role(:spam)

      described_class.reject(appeal: appeal, admin: admin)

      expect(user.reload.spam?).to be true
      expect(article.reload.automod_label).to eq("clear_and_obvious_spam")
    end
  end
end
