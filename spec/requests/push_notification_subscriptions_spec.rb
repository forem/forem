require "rails_helper"

RSpec.describe "PushNotificationSubscriptions", type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "POST /push_notification_subscriptions" do
    it "works" do
      post "/push_notification_subscriptions", params: {
        subscription: {
          keys: { auth: "random", p256dh: "random" },
          endpoint: "random"
        }
      }
      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["endpoint"]).to eq("random")
    end
  end
end
