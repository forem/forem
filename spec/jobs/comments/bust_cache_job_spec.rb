require "rails_helper"

RSpec.describe Comments::BustCacheJob, type: :job do
  include_examples "#enqueues_job", "comments_bust_cache", 5

  describe "#perform_now" do
    let(:edge_cache_commentable_bust_service) { double }
    let(:comment) { create(:comment, commentable: create(:article)) }

    before do
      allow(edge_cache_commentable_bust_service).to receive(:call)
    end

    it "calls the service" do
      described_class.perform_now(comment.id, edge_cache_commentable_bust_service)
      expect(edge_cache_commentable_bust_service).to have_received(:call).
        with(comment.commentable, comment.user.username).once
    end

    it "doesn't call the service with a non existent comment" do
      described_class.perform_now(9999, edge_cache_commentable_bust_service)
      expect(edge_cache_commentable_bust_service).not_to have_received(:call)
    end

    it "doesn't call the service with a comment without a commentable" do
      comment.update_columns(commentable_id: nil, commentable_type: nil)
      described_class.perform_now(comment, edge_cache_commentable_bust_service)
      expect(edge_cache_commentable_bust_service).not_to have_received(:call)
    end
  end
end
