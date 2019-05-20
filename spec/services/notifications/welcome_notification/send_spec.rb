require "rails_helper"

RSpec.describe Notifications::WelcomeNotification::Send, type: :service do
  describe "::call" do
    before do
      allow(User).to receive(:dev_account).and_return(create(:user))
    end

    it "checks a newly created welcome notification", :aggregate_failures do
      welcome_broadcast = create(:broadcast, :onboarding)
      welcome_notification = described_class.call(create(:user).id, welcome_broadcast)

      expect(welcome_notification).to be_kind_of(Notification)
      expect(welcome_notification.notifiable_type).to eq "Broadcast"
      expect(welcome_notification.action).to eq "Onboarding"
      expect(welcome_notification.json_data["broadcast"]["processed_html"]).to eq welcome_broadcast.processed_html
    end
  end
end
