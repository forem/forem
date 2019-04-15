require "rails_helper"

RSpec.describe Notifications::NewCommentJob, type: :job do
  include_examples "#enqueues_job", "send_new_comment_notification", 5

  describe "#perform_now" do
    let(:new_comment_service) { double }

    before do
      allow(new_comment_service).to receive(:call)
    end

    it "calls the service" do
      comment = create(:comment, commentable: create(:article))

      described_class.perform_now(comment.id, new_comment_service)
      expect(new_comment_service).to have_received(:call).with(comment).once
    end

    it "doesn't call a service if a nonexistent comment passed" do
      described_class.perform_now(Comment.maximum(:id).to_i + 1, new_comment_service)
      expect(new_comment_service).not_to have_received(:call)
    end
  end
end
