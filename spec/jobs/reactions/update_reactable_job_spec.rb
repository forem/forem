require "rails_helper"

RSpec.describe Reactions::UpdateReactableJob, type: :job do
  describe "#perform_later" do
    it "enqueues the job" do
      ActiveJob::Base.queue_adapter = :test
      expect do
        described_class.perform_later(2)
      end.to have_enqueued_job.with(2).on_queue("update_reactable")
    end
  end

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
      comment.update_columns(updated_at: Time.now - 1.day)
      now = Time.now
      described_class.perform_now(comment_reaction.id)
      comment.reload
      expect(comment.updated_at).to be >= now
    end

    it "doesn't fail if a reaction doesn't exist" do
      described_class.perform_now(Reaction.maximum(:id).to_i + 1)
    end
  end
end
