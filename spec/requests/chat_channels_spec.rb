require "rails_helper"

RSpec.describe "ChatChannels", type: :request do
  describe "GET /chat_channels/:id" do
    context "when request is valid" do
      let(:chat_channel) { create(:chat_channel) }

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
end
