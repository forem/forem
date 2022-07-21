require "rails_helper"

RSpec.describe Reaction, type: :model do
  let(:user) { create(:user, registered_at: 20.days.ago) }
  let(:article) { create(:article, user: user) }
  let(:reaction) { build(:reaction, reactable: article, user: user) }

  describe "builtin validations" do
    subject { build(:reaction, reactable: article, user: user) }

    it { is_expected.to belong_to(:user) }
    it { is_expected.to validate_inclusion_of(:category).in_array(Reaction::CATEGORIES) }
    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(%i[reactable_id reactable_type category]) }
  end

  describe ".user_has_been_given_too_many_spammy_article_reactions?" do
    it "performs a valid query for the user" do
      expect { described_class.user_has_been_given_too_many_spammy_article_reactions?(user: user) }.not_to raise_error
    end

    it "performs a valid query for the user with the include_user_profile logic" do
      expect do
        described_class.user_has_been_given_too_many_spammy_article_reactions?(user: user,
                                                                               include_user_profile: true)
      end.not_to raise_error
    end
  end

  describe "counter_culture" do
    context "when a reaction is created" do
      it "increments reaction count on user" do
        expect do
          create(:reaction, user: user)
        end.to change { user.reload.reactions_count }.by(1)
      end
    end

    context "when a reaction is destroyed" do
      it "decrements reaction count on user" do
        reaction = create(:reaction, user: user)
        expect do
          reaction.destroy
        end.to change { user.reload.reactions_count }.by(-1)
      end
    end
  end

  describe "validations" do
    it "allows like reaction for users without trusted role" do
      reaction.category = "like"
      expect(reaction).to be_valid
    end

    it "does not allow reactions outside of allowed list" do
      reaction.category = "woozlewazzle"
      expect(reaction).not_to be_valid
    end

    it "does not allow vomit reaction for users without trusted role" do
      allow(Settings::General).to receive(:mascot_user_id).and_return(user.id + 1)
      reaction.category = "vomit"
      expect(reaction).not_to be_valid
    end

    it "does not allow thumbsdown reaction for users without trusted role" do
      allow(Settings::General).to receive(:mascot_user_id).and_return(user.id + 1)
      reaction.category = "thumbsdown"
      expect(reaction).not_to be_valid
    end

    it "does not allow reaction on unpublished article" do
      reaction = build(:reaction, user: user, reactable: article)
      expect(reaction).to be_valid
      article.update_column(:published, false)
      reaction = build(:reaction, user: user, reactable: article)
      expect(reaction).not_to be_valid
    end

    it "assigns 0 points if reaction is invalid" do
      reaction.update(status: "invalid")
      expect(reaction.points).to eq(0)
    end

    it "assigns extra 5 points if reaction is to comment on author's post" do
      comment = create(:comment, commentable: article)
      comment_reaction = create(:reaction, reactable: comment, user: user)
      expect(comment_reaction.points).to eq(5.0)
    end

    it "does not extra 5 points if reaction is to comment on author's post" do
      second_user = create(:user)
      second_article = create(:article, user: second_user)
      comment = create(:comment, commentable: second_article)
      comment_reaction = create(:reaction, reactable: comment, user: user)
      expect(comment_reaction.points).to eq(1)
    end

    it "assigns the correct points if reaction is confirmed" do
      reaction_points = reaction.points
      reaction.update(status: "confirmed")
      expect(reaction.points).to eq(reaction_points * 2)
    end

    it "assigns fractional points to new users on create" do
      newish_user = create(:user, registered_at: 3.days.ago)
      reaction = create(:reaction, reactable: article, user: newish_user)
      expect(reaction.points).to be_within(0.1).of(0.3)
    end

    it "Does not assign new fractional logic on re-save" do
      reaction.save
      original_points = reaction.points
      reaction.user.update_column(:registered_at, 7.days.ago)
      reaction.save
      expect(reaction.points).to eq(original_points)
    end

    it "assigns full points to new users who is also trusted" do
      newish_user = create(:user, registered_at: 3.days.ago)
      newish_user.add_role(:trusted)
      create(:reaction, reactable: article, user: newish_user)
      expect(reaction.points).to be_within(0.1).of(1.0)
    end

    it "assigns full points to new users who is admin" do
      newish_user = create(:user, registered_at: 3.days.ago)
      newish_user.add_role(:admin)
      create(:reaction, reactable: article, user: newish_user)
      expect(reaction.points).to be_within(0.1).of(1.0)
    end

    context "when user is trusted" do
      before { reaction.user.add_role(:trusted) }

      it "allows vomit reactions for users with trusted role" do
        reaction.category = "vomit"
        expect(reaction).to be_valid
      end

      it "allows thumbsdown reactions for users with trusted role" do
        reaction.category = "thumbsdown"
        expect(reaction).to be_valid
      end
    end
  end

  describe "#skip_notification_for?" do
    let(:receiver) { build(:user) }
    let(:reaction) { build(:reaction, reactable: build(:article), user: nil) }

    it "is normally false" do
      expect(reaction.skip_notification_for?(receiver)).to be(false)
    end

    it "is true when points are negative" do
      reaction.points = -2
      expect(reaction.skip_notification_for?(receiver)).to be(true)
    end

    it "is true when the person who reacted is the same as the reactable owner" do
      user_id = User.maximum(:id).to_i + 1
      reaction.user_id = user_id
      reaction.reactable.user_id = user_id
      expect(reaction.skip_notification_for?(user)).to be(true)
    end

    it "is true for inavlidated reactions" do
      reaction.status = "invalid"
      expect(reaction.skip_notification_for?(user)).to be(true)
    end

    context "when reactable is a user" do
      let(:user) { create(:user) }
      let(:reaction) { build(:reaction, reactable: user, user: nil) }

      it "returns true if the reactable is the user that reacted" do
        reaction.user_id = user.id
        expect(reaction.skip_notification_for?(receiver)).to be(true)
      end

      it "returns false if the reactable is not the user that reacted" do
        reaction.user_id = create(:user).id
        expect(reaction.skip_notification_for?(receiver)).to be(false)
      end
    end
  end

  describe ".count_for_article" do
    it "counts the reactions an article has grouped by category" do
      create(:reaction, reactable: article, user: user, category: "like")
      create(:reaction, reactable: article, user: user, category: "unicorn")

      expected_result = [
        { category: "like", count: 1 },
        { category: "readinglist", count: 0 },
        { category: "unicorn", count: 1 },
      ]
      expect(described_class.count_for_article(article.id)).to eq(expected_result)
    end
  end

  context "when callbacks are called after create" do
    describe "field tests" do
      let!(:user) { create(:user, :trusted) }

      before do
        # making sure there are no other enqueued jobs from other tests
        sidekiq_perform_enqueued_jobs(only: Users::RecordFieldTestEventWorker)
      end

      it "enqueues a Users::RecordFieldTestEventWorker for giving a like to an article" do
        article = create(:article, user: user)
        sidekiq_assert_enqueued_jobs(1, only: Users::RecordFieldTestEventWorker) do
          create(:reaction, reactable: article, user: user, category: "like")
        end
      end

      it "does not enqueue a Users::RecordFieldTestEventWorker for giving a privileged reaction to an article" do
        article = create(:article, user: user)
        sidekiq_assert_enqueued_jobs(0, only: Users::RecordFieldTestEventWorker) do
          create(:reaction, reactable: article, user: user, category: "thumbsdown")
        end
      end

      it "does not enqueue a Users::RecordFieldTestEventWorker for giving a like to a comment" do
        comment = create(:comment, user: user)
        sidekiq_assert_enqueued_jobs(0, only: Users::RecordFieldTestEventWorker) do
          create(:reaction, reactable: comment, user: user, category: "like")
        end
      end
    end

    describe "slack messages" do
      let!(:user) { create(:user, :trusted) }
      let!(:article) { create(:article, user: user) }

      before do
        # making sure there are no other enqueued jobs from other tests
        sidekiq_perform_enqueued_jobs(only: Slack::Messengers::Worker)
      end

      it "queues a slack message to be sent for a vomit reaction" do
        sidekiq_assert_enqueued_jobs(1, only: Slack::Messengers::Worker) do
          create(:reaction, reactable: article, user: user, category: "vomit")
        end
      end

      it "does not queue a message for a like reaction" do
        sidekiq_assert_no_enqueued_jobs(only: Slack::Messengers::Worker) do
          create(:reaction, reactable: article, user: user, category: "like")
        end
      end

      it "does not queue a message for a thumbsdown reaction" do
        sidekiq_assert_no_enqueued_jobs(only: Slack::Messengers::Worker) do
          create(:reaction, reactable: article, user: user, category: "thumbsdown")
        end
      end
    end
  end

  context "when callbacks are called after save" do
    let!(:reaction) { build(:reaction, category: "like", reactable: article, user: user) }

    describe "enqueues the correct worker" do
      it "BustReactableCacheWorker" do
        sidekiq_assert_enqueued_with(job: Reactions::BustReactableCacheWorker) do
          reaction.save
        end
      end

      it "BustHomepageCacheWorker" do
        sidekiq_assert_enqueued_with(job: Reactions::BustHomepageCacheWorker) do
          reaction.save
        end
      end
    end

    it "updates updated_at if the reactable is a comment" do
      sidekiq_perform_enqueued_jobs do
        updated_at = 1.day.ago
        comment = create(:comment, commentable: article, updated_at: updated_at)
        reaction.update(reactable: comment)
        expect(comment.reload.updated_at).to be > updated_at
      end
    end
  end

  context "when callbacks are called before destroy" do
    let(:reaction) { create(:reaction, reactable: article, user: user) }

    it "enqueues a ScoreCalcWorker on article reaction destroy" do
      sidekiq_assert_enqueued_with(job: Articles::ScoreCalcWorker, args: [article.id]) do
        reaction.destroy
      end
    end

    it "updates reactable without delay" do
      allow(reaction).to receive(:update_reactable_without_delay)
      reaction.destroy
      expect(reaction).to have_received(:update_reactable_without_delay)
    end

    it "busts reactable cache without delay" do
      allow(reaction).to receive(:bust_reactable_cache_without_delay)
      reaction.destroy
      expect(reaction).to have_received(:bust_reactable_cache_without_delay)
    end
  end

  describe ".related_negative_reactions_for_user" do
    let(:moderator) { create(:user, :trusted) }

    it "returns vomit reactions on user's articles" do
      article = create(:article, user: user)
      reaction = create(:vomit_reaction, user: moderator, reactable: article)

      expect(described_class.related_negative_reactions_for_user(user).first.id).to eq(reaction.id)
    end

    it "returns vomit reactions on user's comments" do
      comment = create(:comment, user: user)
      reaction = create(:vomit_reaction, user: moderator, reactable: comment)

      expect(described_class.related_negative_reactions_for_user(user).first.id).to eq(reaction.id)
    end

    it "returns the user's vomit reactions" do
      reaction = create(:vomit_reaction, user: moderator, reactable: user)

      expect(described_class.related_negative_reactions_for_user(moderator).first.id).to eq(reaction.id)
    end
  end
end
