require "rails_helper"

RSpec.describe Reactions::BustReactableCacheJob, type: :job do
  describe "#perform_later" do
    it "enqueues the job" do
      ActiveJob::Base.queue_adapter = :test
      expect do
        described_class.perform_later(2)
      end.to have_enqueued_job.with(2).on_queue("bust_reactable_cache")
    end
  end

  describe "#perform_now" do
    let(:user) { create(:user) }
    let(:article) { create(:article) }
    let(:reaction) { create(:reaction, reactable: article, user: user) }
    let(:comment) { create(:comment, commentable: article) }
    let(:comment_reaction) { create(:reaction, reactable: comment, user: user) }
    let(:buster) { double }

    before do
      allow(buster).to receive(:bust)
    end

    it "busts the reactable article cache" do
      described_class.perform_now(reaction.id, buster)
      expect(buster).to have_received(:bust).with(user.path).once
      expect(buster).to have_received(:bust).with("/reactions?article_id=#{article.id}").once
    end

    it "busts the reactable comment cache" do
      described_class.perform_now(comment_reaction.id, buster)
      expect(buster).to have_received(:bust).with(user.path).once
      expect(buster).to have_received(:bust).with("/reactions?commentable_id=#{article.id}&commentable_type=Article").once
    end

    it "doesn't fail if a reaction doesn't exist" do
      described_class.perform_now(Reaction.maximum(:id).to_i + 1)
    end
  end
end
