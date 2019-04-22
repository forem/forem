require "rails_helper"

RSpec.describe Notifications::WelcomeNotificationJob, type: :job do
  include_examples "#enqueues_job", "send_welcome_notification"

  describe "::perform_now" do
    let(:welcome_notification_service) { double }

    before do
      create(:broadcast, :onboarding)
      allow(welcome_notification_service).to receive(:call)
      allow(User).to receive(:dev_account).and_return(create(:user))
    end

    it "calls the service" do
      user = create(:user)

      described_class.perform_now(user.id, welcome_notification_service)
      expect(welcome_notification_service).to have_received(:call).once
    end
  end
end
