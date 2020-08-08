require "rails_helper"

RSpec.describe Comments::SendNewCommentNotificationsWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "high_priority", 1

  describe "#perform_now" do
    let(:worker) { subject }

    it "sends new comment notification" do
      allow(Notifications::NewComment::Send).to receive(:call)
      comment = create(:comment)
      worker.perform(comment.id)

      expect(Notifications::NewComment::Send).to have_received(:call)
    end
  end
end
