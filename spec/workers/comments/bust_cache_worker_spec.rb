require "rails_helper"

RSpec.describe Comments::BustCacheWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "high_priority", 1

  describe "#perform" do
    let(:worker) { subject }

    context "with comment" do
      let(:comment) { double }
      let(:comment_id) { 1 }
      let(:commentable) { double }

      before do
        allow(comment).to receive_messages(
          commentable: commentable,
          commentable_type: "Article",
          commentable_id: 2,
        )
        allow(Comment).to receive(:find_by).with(id: comment_id).and_return(comment)
        allow(comment).to receive(:purge)
        allow(commentable).to receive(:purge)
        allow(Articles::UpdateDependentEmbedsWorker).to receive(:perform_async)
      end

      it "does not call purge on comment when commentable is not available" do
        allow(comment).to receive(:commentable).and_return(nil)

        worker.perform(comment_id)

        expect(comment).not_to have_received(:purge)
        expect(commentable).not_to have_received(:purge)
      end

      it "does not call purge on commentable when commentable is not available" do
        allow(comment).to receive(:commentable).and_return(nil)

        worker.perform(comment_id)

        expect(commentable).not_to have_received(:purge)
      end

      it "purges comment and commentable without triggering multi-hop UpdateDependentEmbedsWorker cascades" do
        worker.perform(comment_id)

        expect(comment).to have_received(:purge)
        expect(commentable).to have_received(:purge)
        expect(Articles::UpdateDependentEmbedsWorker).not_to have_received(:perform_async)
      end
    end

    context "without comment" do
      it "does not break" do
        expect { worker.perform(nil) }.not_to raise_error
      end
    end
  end
end
