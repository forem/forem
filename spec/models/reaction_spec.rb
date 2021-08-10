require "rails_helper"

RSpec.describe Reaction, type: :model do
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user) }
  let(:reaction) { build(:reaction, reactable: article) }

  describe "builtin validations" do
    subject { build(:reaction, reactable: article, user: user) }

    it { is_expected.to belong_to(:user) }
    it { is_expected.to validate_inclusion_of(:category).in_array(Reaction::CATEGORIES) }
    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(%i[reactable_id reactable_type category]) }
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

    it "assigns the correct points if reaction is confirmed" do
      reaction_points = reaction.points
      reaction.update(status: "confirmed")
      expect(reaction.points).to eq(reaction_points * 2)
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

    context "when false" do
      it "is false when points are positive" do
        reaction.points = 1
        expect(reaction.skip_notification_for?(receiver)).to be(false)
      end

      it "is false when the person who reacted is not the same as the reactable owner" do
        user_id = User.maximum(:id).to_i + 1
        reaction.user_id = user_id
        reaction.reactable.user_id = user_id + 1
        expect(reaction.skip_notification_for?(user)).to be(false)
      end

      it "is false when receive_notifications is true" do
        reaction.reactable.receive_notifications = true
        expect(reaction.skip_notification_for?(receiver)).to be(false)
      end
    end

    context "when true" do
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
end
