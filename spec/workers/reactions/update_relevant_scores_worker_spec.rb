require "rails_helper"

RSpec.describe Reactions::UpdateRelevantScoresWorker, type: :worker do
  describe "#perform" do
    let(:reacting_user) { create(:user, :admin) }
    let(:worker) { subject }

    it "doesn't fail if a reaction doesn't exist" do
      expect do
        worker.perform(Reaction.maximum(:id).to_i + 1)
      end.not_to raise_error
    end

    context "when reaction is to an article" do
      let(:article) { create(:article) }
      let(:reaction) { create(:reaction, reactable: article, user: reacting_user) }

      it "queues reactable updater" do
        sidekiq_assert_enqueued_with(job: Reactions::UpdateReactableWorker, args: [article.id, "Article"]) do
          worker.perform(reaction.id)
        end
      end

      it "queues follow points updater" do
        sidekiq_assert_enqueued_with(job: Follows::UpdatePointsWorker, args: [article.id, reacting_user.id]) do
          worker.perform(reaction.id)
        end
      end

      it "does not queue follow points updater if the reaction is not public" do
        reaction.update_columns(category: "vomit")

        sidekiq_assert_not_enqueued_with(job: Follows::UpdatePointsWorker) do
          worker.perform(reaction.id)
        end
      end
    end

    context "when reaction is to a comment" do
      let(:comment) { create(:comment) }
      let(:reaction) { create(:reaction, reactable: comment, user: reacting_user) }

      it "queues reactable updater" do
        sidekiq_assert_enqueued_with(job: Reactions::UpdateReactableWorker, args: [comment.id, "Comment"]) do
          worker.perform(reaction.id)
        end
      end

      it "does not queue follow points updater" do
        sidekiq_assert_not_enqueued_with(job: Follows::UpdatePointsWorker) do
          worker.perform(reaction.id)
        end
      end
    end

    context "when reaction is to a user" do
      let(:user) { create(:user) }
      let(:reaction) { create(:vomit_reaction, reactable: user, user: reacting_user) }

      it "queues reactable updater" do
        sidekiq_assert_enqueued_with(job: Reactions::UpdateReactableWorker, args: [user.id, "User"]) do
          worker.perform(reaction.id)
        end
      end

      it "does not queue follow points updater" do
        sidekiq_assert_not_enqueued_with(job: Follows::UpdatePointsWorker) do
          worker.perform(reaction.id)
        end
      end
    end
  end
end
