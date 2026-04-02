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

    context "when mode=detailed parameter is passed" do
      it "returns count and extended metadata in JSON" do
        sign_in user
        
        # Read notification (older)
        old_time = 2.days.ago
        create(:notification, user: user, action: "Reaction", read: true, read_at: old_time, notified_at: 3.days.ago)

        # Unread notification (newer)
        new_notification = create(:notification, user: user, action: "New Follower", notified_at: 1.day.ago)

        get "/notifications/counts", params: { mode: "detailed" }
        json_response = JSON.parse(response.body)
        
        expect(json_response["count"]).to eq(1)
        expect(json_response["last_notification_id"]).to eq(new_notification.id)
        expect(json_response["read_at"]).to be_nil # because newest is unread
        expect(json_response["notified_at"]).to eq(new_notification.notified_at.as_json)
        expect(json_response["action"]).to eq("New Follower")
      end

      it "returns count 0 and nil metadata if no user" do
        get "/notifications/counts", params: { mode: "detailed" }
        json_response = JSON.parse(response.body)
        
        expect(json_response["count"]).to eq(0)
        expect(json_response["last_notification_id"]).to be_nil
        expect(json_response["read_at"]).to be_nil
        expect(json_response["notified_at"]).to be_nil
      end
    end

    it "returns 0 if no user is present (plain default mode)" do
      get "/notifications/counts"
      expect(response.body).to eq("0")
    end
  end
end
