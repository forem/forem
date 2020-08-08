require "rails_helper"

RSpec.describe Comments::CreateNotificationSubscriptionWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "high_priority", 1

  describe "#perform_now" do
    let(:worker) { subject }

    it "creates NotificationSubscription for comment" do
      comment = create(:comment)
      worker.perform(comment.user_id, comment.id)

      expect(NotificationSubscription.last.notifiable).to eq(comment)
    end
  end
end
