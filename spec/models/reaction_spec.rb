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
      reaction.category = "vomit"
      expect(reaction).not_to be_valid
    end

    it "does not allow thumbsdown reaction for users without trusted role" do
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

  describe "#after_commit" do
    context "when category is readingList and reactable is published" do
      it "on update enqueues job to index reaction to elasticsearch" do
        reaction.save
        sidekiq_assert_enqueued_with(job: Search::IndexToElasticsearchWorker, args: [described_class.to_s, reaction.id]) do
          reaction.update(category: "readinglist")
        end
      end

      it "on create enqueues job to index reaction to elasticsearch" do
        reaction.category = "readinglist"
        sidekiq_assert_enqueued_with(job: Search::IndexToElasticsearchWorker) do
          reaction.save
        end
      end

      it "on destroy enqueues job to delete reaction from elasticsearch" do
        reaction.category = "readinglist"
        reaction.save
        sidekiq_assert_enqueued_with(job: Search::RemoveFromElasticsearchIndexWorker, args: [described_class::SEARCH_CLASS.to_s, reaction.id]) do
          reaction.destroy
        end
      end
    end

    context "when category is not readinglist" do
      before do
        reaction.category = "like"
        allow(reaction.user).to receive(:index_to_elasticsearch)
        allow(reaction.reactable).to receive(:index_to_elasticsearch)
        sidekiq_perform_enqueued_jobs
      end

      it "on update does not enqueue job to index reaction to elasticsearch" do
        reaction.save
        sidekiq_assert_no_enqueued_jobs(only: Search::IndexToElasticsearchWorker) do
          reaction.update(category: "unicorn")
        end
      end

      it "on create does not enqueue job to index reaction to elasticsearch" do
        sidekiq_assert_no_enqueued_jobs(only: Search::IndexToElasticsearchWorker) do
          reaction.save
        end
      end

      it "on destroy does not enqueue job to delete reaction from elasticsearch" do
        reaction.save
        sidekiq_assert_no_enqueued_jobs(only: Search::RemoveFromElasticsearchIndexWorker) do
          reaction.destroy
        end
      end
    end
  end

  describe "#skip_notification_for?" do
    let_it_be(:receiver) { build(:user) }
    let_it_be(:reaction) { build(:reaction, reactable: build(:article), user: nil) }

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

      it "is true when the receive_notifications is false" do
        reaction.reactable.receive_notifications = false
        expect(reaction.skip_notification_for?(receiver)).to be(true)
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
    describe "slack notifications" do
      let_it_be_changeable(:user) { create(:user, :trusted) }
      let_it_be_readonly(:article) { create(:article, user: user) }

      before do
        # making sure there are no other enqueued jobs from other tests
        sidekiq_perform_enqueued_jobs(only: SlackBotPingWorker)
      end

      it "notifies proper slack channel about vomit reaction" do
        url = "#{ApplicationConfig['APP_PROTOCOL']}#{ApplicationConfig['APP_DOMAIN']}"
        message = "#{user.name} (#{url}#{user.path})\nreacted with a vomit on\n#{url}#{article.path}"
        args = {
          message: message,
          channel: "abuse-reports",
          username: "abuse_bot",
          icon_emoji: ":cry:"
        }.stringify_keys

        sidekiq_assert_enqueued_with(job: SlackBotPingWorker, args: [args]) do
          create(:reaction, reactable: article, user: user, category: "vomit")
        end
      end

      it "does not send notification for like reaction" do
        sidekiq_assert_no_enqueued_jobs(only: SlackBotPingWorker) do
          create(:reaction, reactable: article, user: user, category: "like")
        end
      end

      it "does not send notification for thumbsdown reaction" do
        sidekiq_assert_no_enqueued_jobs(only: SlackBotPingWorker) do
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

    it "updates updated_at for the user" do
      sidekiq_perform_enqueued_jobs do
        updated_at = user.updated_at
        Timecop.travel(1.day.from_now) do
          reaction.save
          expect(user.reload.updated_at).to be > updated_at
        end
      end
    end
  end

  context "when callbacks are called before destroy" do
    it "enqueues a ScoreCalcWorker on article reaction destroy" do
      reaction = create(:reaction, reactable: article, user: user)
      sidekiq_assert_enqueued_with(job: Articles::ScoreCalcWorker, args: [article.id]) do
        reaction.destroy
      end
    end
  end
end
