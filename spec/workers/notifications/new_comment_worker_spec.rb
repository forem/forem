require "rails_helper"

RSpec.describe Notifications::NewCommentWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "medium_priority", 1

  describe "#perform" do
    let(:worker) { subject }
    let(:comment) { create(:comment, commentable: create(:article)) }
    let(:new_comment_service) { double }

    before do
      allow(new_comment_service).to receive(:call)
    end

    it "with valid comment calls NewComment service" do
      worker.perform(comment.id) do
        expect(new_comment_service).to have_received(:call).with(comment).once
      end
    end

    it "without valid comment does not call NewComment service" do
      worker.perform(nil) do
        expect(new_comment_service).not_to have_received(:call)
      end
    end
  end
end
