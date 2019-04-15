require "rails_helper"

RSpec.describe Reactions::UpdateReactableJob, type: :job do
  include_examples "#enqueues_job", "update_reactable", 2

  describe "#perform_now" do
    let(:article) { create(:article) }
    let(:reaction) { create(:reaction, reactable: article) }
    let(:comment) { create(:comment, commentable: article) }
    let(:comment_reaction) { create(:reaction, reactable: comment) }

    it "updates the reactable Article" do
      expect do
        described_class.perform_now(reaction.id)
      end.to have_enqueued_job(Articles::ScoreCalcJob).exactly(:once).with(article.id)
    end

    it "updates the reactable Comment" do
      updated_at = 1.day.ago
      comment.update_columns(updated_at: updated_at)
      described_class.perform_now(comment_reaction.id)
      expect(comment.reload.updated_at).to be > updated_at
    end

    it "doesn't fail if a reaction doesn't exist" do
      described_class.perform_now(Reaction.maximum(:id).to_i + 1)
    end
  end
end
