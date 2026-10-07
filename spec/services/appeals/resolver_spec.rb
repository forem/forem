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

    it "still reinstates the user when the appealed content was deleted" do
      appeal_id = appeal.id
      article.delete

      expect(described_class.approve(appeal: FlagAppeal.find(appeal_id), admin: admin)).to be true
      expect(user.reload.spam_or_suspended?).to be false
    end
  end

  describe ".reject" do
    it "marks the appeal as rejected" do
      expect(described_class.reject(appeal: appeal, admin: admin)).to be true

      appeal.reload
      expect(appeal.status).to eq("rejected")
      expect(appeal.resolved_by).to eq(admin)
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
