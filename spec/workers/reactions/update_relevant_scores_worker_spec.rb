require "rails_helper"

RSpec.describe Reactions::UpdateRelevantScoresWorker, type: :worker, throttled_call: true do
  describe "#perform" do
    let(:article) { create(:article) }
    let(:reaction) { create(:reaction, reactable: article) }
    let(:comment) { create(:comment, commentable: article) }
    let(:comment_reaction) { create(:reaction, reactable: comment) }
    let(:worker) { subject }

    it "kicks off point update if article" do
      sidekiq_assert_enqueued_with(job: Follows::UpdatePointsWorker) do
        worker.perform(reaction.id)
      end
    end

    it "does not kick off points updater if not comment reaction" do
      sidekiq_assert_not_enqueued_with(job: Follows::UpdatePointsWorker) do
        worker.perform(comment_reaction.id)
      end
    end

    it "does not kick off points updater if reaction is non-public" do
      reaction.update_column(:category, "vomit")
      sidekiq_assert_not_enqueued_with(job: Follows::UpdatePointsWorker) do
        worker.perform(reaction.id)
      end
    end

    it "updates the reactable Article" do
      sidekiq_assert_enqueued_with(job: Articles::ScoreCalcWorker) do
        worker.perform(reaction.id)
      end
    end

    it "recalculates score if reactable is User" do
      user = create(:user)
      reaction.update_columns(category: "vomit", reactable_id: user.id, reactable_type: "User", points: -50)
      worker.perform(reaction.id)
      expect(user.reload.score).to be < -1
    end

    it "updates the reactable Comment" do
      updated_at = 1.day.ago
      comment.update_columns(updated_at: updated_at)
      worker.perform(comment_reaction.id)
      expect(comment.reload.updated_at).to be > updated_at
    end

    it "doesn't fail if a reaction doesn't exist" do
      expect do
        worker.perform(Reaction.maximum(:id).to_i + 1)
      end.not_to raise_error
    end

    it "uses a throttled call for syncing the reactions count" do
      worker.perform(reaction.id)

      expect(ThrottledCall).to have_received(:perform)
        .with(:sync_reactions_count, throttle_for: instance_of(ActiveSupport::Duration))
    end
  end
end
