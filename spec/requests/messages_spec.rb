require "rails_helper"

RSpec.describe "Messages", type: :request do
  let(:user) { create(:user) }
  let(:chat_channel) { create(:chat_channel) }

  describe "POST /messages" do
    let(:new_message) do
      {
        message_markdown: "hi",
        user_id: user.id,
        chat_channel_id: chat_channel.id
      }
    end

    it "requires user to be signed in" do
      post "/messages", params: { message: {} }
      expect(response.status).to eq(302)
    end
    # Pusher::Error

    context "when user is signed in" do
      before do
        allow(Pusher).to receive(:trigger).and_return(true)
        sign_in user
        post "/messages", params: { message: new_message }
      end

      it "returns 201 upon success" do
        expect(response.status).to eq(201)
      end

      it "returns in json" do
        expect(response.content_type).to eq("application/json")
      end
    end

    # context "when Pusher isn't cooperating" do
    #   before do
    #     allow(Pusher).to receive(:trigger).and_raise(Pusher::Error)
    #     sign_in user
    #     post "/messages", params: { message: new_message }
    #   end

    #   it "returns proper message" do
    #     expect(response.body).to include("could not trigger Pusher")
    #   end
    # end
  end
end
