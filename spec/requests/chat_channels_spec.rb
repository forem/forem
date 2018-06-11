require "rails_helper"

RSpec.describe "ChatChannels", type: :request do
  let(:user) { create(:user) }
  let(:test_subject) { create(:user) }
  let(:chat_channel) { create(:chat_channel) }

  before do
    sign_in user
    chat_channel.add_users([user])
  end


  describe "GET /chat_channels/:id" do
    context "when request is valid" do
      before do
        get "/chat_channels/#{chat_channel.id}", headers: { HTTP_ACCEPT: "application/json" }
      end

      it "returns 200" do
        expect(response.status).to eq(200)
      end

      it "returns the channel" do
        expect(response).to render_template(:show)
      end
    end

    context "when request is invalid" do
      before { get "/chat_channels/1" }

      it "returns proper error message" do
        expect(response.body).to include("invalid")
      end

      it "returns 401" do
        expect(response.status).to eq(401)
      end
    end
  end

  describe "POST /chat_channels/:id/moderate" do
    it "returns 401 unless user is logged in" do
      post "/chat_channels/#{chat_channel.id}/moderate",
        params: { chat_channel: { command: "/ban huh" } },
        headers: { HTTP_ACCEPT: "application/json" }
      expect(response.status).to eq(401)
    end

    it "returns 401 if user is logged in but not authorized" do
      sign_in user
      post "/chat_channels/#{chat_channel.id}/moderate",
        params: { chat_channel: { command: "/ban huh" } },
        headers: { HTTP_ACCEPT: "application/json" }
      expect(response.status).to eq(401)
    end

    context "when user is logged-in and authorized" do
      before do
        user.add_role :super_admin
        sign_in user
        allow(Pusher).to receive(:trigger).and_return(true)
      end

      it "enforces chat_channel_params" do
        post "/chat_channels/#{chat_channel.id}/moderate",
          params: { chat_channel: { command: "/ban #{test_subject.username}" } }
        expect(response.status).to eq(200)
      end
    end
  end
end
