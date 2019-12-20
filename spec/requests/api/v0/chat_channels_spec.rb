require "rails_helper"

RSpec.describe "Api::V0::ChatChannels", type: :request do
  let(:user) { create(:user) }
  let(:chat_channel) { create(:chat_channel) }
  let(:invite_channel) { create(:chat_channel, channel_type: "invite_only") }

  before { sign_in user }

  describe "GET /api/chat_channels/:id" do
    it "returns 200 if user is a member of the channel" do
      chat_channel.add_users([user])
      get "/api/chat_channels/#{chat_channel.id}"
      expect(response).to have_http_status(:ok)
    end

    it "returns a 404 if user is not a memeber of the channel" do
      get "/api/chat_channels/#{invite_channel.id}"
      expect(response.status).to eq(404)
    end

    it "returns a 404 if channel is not found" do
      get "/api/chat_channels/#{invite_channel.id + 100}"
      expect(response.status).to eq(404)
    end
  end
end
