require "rails_helper"

RSpec.describe Comments::BustCacheJob, type: :job do
  include_examples "#enqueues_job", "comments_bust_cache", 5

  describe "#perform_now" do
    let(:edge_cache_commentable_bust_service) { double }

    before do
      allow(edge_cache_commentable_bust_service).to receive(:call)
    end

    context "with comment" do
      let(:comment) { double }
      let(:comment_id) { 1 }
      let(:commentable) { double }

      before do
        allow(comment).to receive(:commentable).and_return(commentable)
        allow(comment).to receive(:purge)
        allow(commentable).to receive(:purge)
        allow(Comment).to receive(:find_by).with(id: comment_id).and_return(comment)
      end

      it "calls the service" do
        described_class.perform_now(comment_id, edge_cache_commentable_bust_service)

        expect(edge_cache_commentable_bust_service).to have_received(:call).with(comment.commentable).once
      end

      it "does not call purge on comment when commentable is not available" do
        allow(comment).to receive(:commentable).and_return(nil)

        described_class.perform_now(comment_id, edge_cache_commentable_bust_service)

        expect(comment).not_to have_received(:purge)
        expect(commentable).not_to have_received(:purge)
      end

      it "does not call purge on commentable when commentable is not available" do
        allow(comment).to receive(:commentable).and_return(nil)

        described_class.perform_now(comment_id, edge_cache_commentable_bust_service)

        expect(commentable).not_to have_received(:purge)
      end

      it "does not call the service when commentable is not available" do
        allow(comment).to receive(:commentable).and_return(nil)

        described_class.perform_now(comment_id, edge_cache_commentable_bust_service)

        expect(edge_cache_commentable_bust_service).not_to have_received(:call)
      end
    end

    context "without comment" do
      it "does not break" do
        expect { described_class.perform_now(nil, edge_cache_commentable_bust_service) }.not_to raise_error
      end

      it "doesn't call the service" do
        described_class.perform_now(nil, edge_cache_commentable_bust_service)

        expect(edge_cache_commentable_bust_service).not_to have_received(:call)
      end
    end
  end
end
