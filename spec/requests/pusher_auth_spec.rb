require "rails_helper"

RSpec.describe "PusherAuth", type: :request do
  let(:user) { create(:user) }
  let(:chat_channel) { build(:chat_channel) }
  let(:stub_token) { "123123123" }

  describe "POST /pusher/auth" do
    it "returns forbidden with invalid channel" do
      post "/pusher/auth", params: {
        channel_name: "hey hey hey hey"
      }
      expect(response.body).to include("Forbidden")
    end
  end

  describe "GET /pusher/beams_auth" do
    it "returns unauthorized if request is not authenticated" do
      get "/pusher/beams_auth?user_id=#{user.id}"
      expect(response).to have_http_status(:unauthorized)
    end

    context "when user is authenticated" do
      before do
        sign_in user
        allow(Pusher::PushNotifications).to receive(:generate_token).and_return(stub_token)
      end

      it "fails if requested user_id does not match the current_user" do
        get "/pusher/beams_auth?user_id=827192730182"
        expect(response).to have_http_status(:unauthorized)
      end

      it "returns a token if request is valid" do
        get "/pusher/beams_auth?user_id=#{user.id}"
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(stub_token)
      end
    end
  end
end
