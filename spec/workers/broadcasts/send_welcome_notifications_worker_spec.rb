require "rails_helper"

RSpec.describe Broadcasts::SendWelcomeNotificationsWorker, type: :worker do
  let(:service) { Broadcasts::WelcomeNotification::Generator }
  let(:worker) { subject }

  include_examples "#enqueues_on_correct_queue", "medium_priority"

  describe "#perform" do
    it "does nothing if Settings::General.welcome_notifications_live_at is nil" do
      allow(Settings::General).to receive(:welcome_notifications_live_at).and_return(nil)
      allow(service).to receive(:call)
      create(:user, created_at: 1.day.ago)
      worker.perform
      expect(service).not_to have_received(:call)
    end

    it "sends welcome notifications to new users" do
      Timecop.freeze do
        allow(Settings::General).to receive(:welcome_notifications_live_at).and_return(3.days.ago)
        allow(User).to receive(:mascot_account).and_return(create(:user))
        welcome_broadcast = create(:welcome_broadcast)
        user = create(:user, created_at: 1.day.ago)
        old_user = create(:user, created_at: 1.year.ago)

        sidekiq_perform_enqueued_jobs(only: "Notifications::WelcomeNotificationWorker") do
          worker.perform
        end

        welcome_notification = user.notifications.find_by(
          notifiable_id: welcome_broadcast.id, notifiable_type: "Broadcast",
        )
        expect(welcome_notification).not_to be_nil
        expect(old_user.notifications.count).to eq(0)
      end
    end
  end
end
