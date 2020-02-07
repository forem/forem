require "rails_helper"

RSpec.describe "Messages", type: :request do
  let(:user) { create(:user) }
  let(:chat_channel) { create(:chat_channel) }

  describe "POST /messages" do
    let(:new_message) do
      {
        message_markdown: "hi",
        user_id: user.id,
        temp_id: "sd78jdssd",
        chat_channel_id: chat_channel.id
      }
    end

    it "requires user to be signed in" do
      post "/messages", params: { message: {} }
      expect(response.status).to eq(302)
    end

    context "when user is signed in" do
      before do
        allow(Pusher).to receive(:trigger).and_return(true)
        sign_in user
        post "/messages", params: { message: new_message }
      end

      it "returns 201 upon success" do
        allow(Pusher).to receive(:trigger).and_return(true)
        expect(response.status).to eq(201)
      end

      it "returns in json" do
        expect(response.content_type).to eq("application/json")
      end
    end

    context "when user is blocked" do
      before do
        sign_in user
        chat_channel.update(status: "blocked")
      end

      it "return unauthorized" do
        post "/messages", params: { message: new_message }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "DELETE /messages/:id" do
    let(:old_message) { create(:message, user_id: user.id) }

    it "requires user to be signed in" do
      expect { delete "/messages/#{old_message.id}" }.to raise_error(Pundit::NotAuthorizedError)
    end

    context "when user is signed in" do
      before do
        allow(Pusher).to receive(:trigger).and_return(true)
        sign_in user
        delete "/messages/#{old_message.id}", params: { message: old_message }
      end

      it "returns message deleted" do
        expect(response.body).to include "deleted"
      end

      it "returns in json" do
        expect(response.content_type).to eq("application/json")
      end
    end
  end

  describe "UPDATE /messages/:id" do
    let(:old_message) { create(:message, user_id: user.id) }

    let(:new_message) do
      {
        message_markdown: "hi",
        user_id: user.id,
        chat_channel_id: chat_channel.id
      }
    end

    it "requires user to be signed in" do
      expect { patch "/messages/#{old_message.id}" }.to raise_error(Pundit::NotAuthorizedError)
    end

    context "when user is signed in" do
      before do
        allow(Pusher).to receive(:trigger).and_return(true)
        sign_in user
        patch "/messages/#{old_message.id}", params: { message: new_message }
      end

      it "returns message updated" do
        expect(response.body).to include "edited"
      end

      it "returns in json" do
        expect(response.content_type).to eq("application/json")
      end
    end
  end
end
