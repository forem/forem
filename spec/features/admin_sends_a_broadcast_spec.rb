require "rails_helper"

feature "Send a broadcast" do
  describe "Onboarding/welcome broadcast" do
    describe "sent broadcast" do
      before do
        @broadcast = FactoryBot.create(:broadcast, :onboarding, :sent)
        @new_user = FactoryBot.create(:user)
        @welcome_notification = Broadcast.send_welcome_notification(@new_user.id)
      end

      it "has a welcome notification" do
        expect(@welcome_notification.notifiable).to eq @broadcast
      end

      it "is properly sent to the new user" do
        expect(@welcome_notification.user).to eq @new_user
      end

      it "has a link to the welcome thread" do
        expect(@broadcast.processed_html.html_safe).to include("/welcome")
      end
    end

    describe "unsent broadcast" do
      before do
        broadcast = FactoryBot.create(:broadcast, :onboarding)
      end

      it "is an unsent broadcast that doesn't create a notification" do
        expect(Notification.all.empty?).to be true
      end
    end
  end
end
