require "rails_helper"

RSpec.describe Notifications::WelcomeNotification::Send, type: :service do
  describe "::call" do
    let!(:welcome_broadcast) { create(:set_up_profile_broadcast) }

    before do
      allow(User).to receive(:mascot_account).and_return(create(:user))
      allow(ForemStatsClient).to receive(:increment)
    end

    it "creates a new welcome notification", :aggregate_failures do
      expect(Notification.find_by(notifiable_id: welcome_broadcast.id)).to be(nil)

      described_class.call(create(:user).id, welcome_broadcast)

      welcome_notification = Notification.find_by(notifiable_id: welcome_broadcast.id)
      expect(welcome_notification).to be_kind_of(Notification)
      expect(welcome_notification.notifiable_type).to eq "Broadcast"
      expect(welcome_notification.action).to eq "Welcome"
      expect(welcome_notification.json_data["broadcast"]["processed_html"]).to eq welcome_broadcast.processed_html
    end

    it "logs to DataDog" do
      described_class.call(create(:user).id, welcome_broadcast)
      welcome_notification = Notification.find_by(notifiable_id: welcome_broadcast.id)
      tags = ["user_id:#{welcome_notification.user_id}", "title:#{welcome_notification.notifiable.title}"]

      expect(ForemStatsClient).to have_received(:increment).with("notifications.welcome", tags: tags)
    end
  end
end
