require "rails_helper"

RSpec.describe "NotificationCounts" do
  let(:user) { create(:user) }
  let(:following_user) { create(:user) }

  describe "GET /notifications/counts" do
    it "returns count if signed in" do
      sign_in user
      follow_instance = following_user.follow(user)
      Notification.send_new_follower_notification_without_delay(follow_instance)

      get "/notifications/counts"
      expect(response.body).to eq("1")
    end

    it "returns 0 if no user is present" do
      get "/notifications/counts"
      expect(response.body).to eq("0")
    end
  end
end
