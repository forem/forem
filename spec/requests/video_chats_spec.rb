require "rails_helper"

RSpec.describe "VideoChats", type: :request do
  let(:user) { create(:user) }

  describe "GET /video_chats/:id" do
    context "with user signed in" do
      before do
        sign_in user
      end

      it "displays basic html for working" do
        get "/video_chats/1"
        expect(response.body).to include("<div class=\"video-chat-wrapper")
      end
    end

    context "without user signed in" do
      it "asks to sign in" do
        get "/video_chats/1"
        expect(response).to redirect_to("/enter")
      end
    end
  end
end
