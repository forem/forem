require "rails_helper"

RSpec.describe "ChatChannelMemberships", type: :request do
  let(:user) { create(:user) }
  let(:second_user) { create(:user) }
  let(:chat_channel) { create(:chat_channel) }

  before do
    sign_in user
    chat_channel.add_users([user])
  end

  describe "POST /chat_channel_memberships" do
    it "creates chat channel invitation" do
      user.add_role(:super_admin)
      mems_num = ChatChannelMembership.all.size
      post "/chat_channel_memberships", params: {
        chat_channel_membership: {
          user_id: second_user.id, chat_channel_id: chat_channel.id
        }
      }
      expect(ChatChannelMembership.all.size).to eq(mems_num + 1)
      expect(ChatChannelMembership.last.status).to eq("pending")
    end

    it "denies chat channel invitation to non-authorized user" do
      expect do
        post "/chat_channel_memberships", params: {
          chat_channel_membership: {
            user_id: second_user.id, chat_channel_id: chat_channel.id
          }
        }
      end.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  describe "PUT /chat_channel_memberships/:id" do
    before do
      user.add_role(:super_admin)
      post "/chat_channel_memberships", params: {
        chat_channel_membership: { user_id: second_user.id, chat_channel_id: chat_channel.id }
      }
    end

    it "accepts chat channel invitation" do
      membership = ChatChannelMembership.last
      sign_in second_user
      put "/chat_channel_memberships/#{membership.id}", params: {
        chat_channel_membership: {
          user_action: "accept"
        }
      }
      expect(ChatChannelMembership.find(membership.id).status).to eq("active")
    end

    it "rejects chat channel invitation" do
      membership = ChatChannelMembership.last
      sign_in second_user
      put "/chat_channel_memberships/#{membership.id}", params: {
        chat_channel_membership: { user_action: "reject" }
      }
      expect(ChatChannelMembership.find(membership.id).status).to eq("rejected")
    end

    it "disallows non-logged-user" do
      membership = ChatChannelMembership.last
      expect do
        put "/chat_channel_memberships/#{membership.id}", params: {
          chat_channel_membership: { user_action: "accept" }
        }
        expect(ChatChannelMembership.find(membership.id).status).to eq("active")
      end.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  describe "DELETE /chat_channel_memberships/:id" do
    before do
      user.add_role(:super_admin)
      post "/chat_channel_memberships", params: {
        chat_channel_membership: { user_id: second_user.id, chat_channel_id: chat_channel.id }
      }
    end

    it "leaves chat channel" do
      membership = ChatChannelMembership.last
      sign_in second_user
      delete "/chat_channel_memberships/#{membership.chat_channel.id}", params: {}
      expect(ChatChannelMembership.find(membership.id).status).to eq("left_channel")
    end
  end

  describe "GET /chat_channel_memberships/find_by_chat_channel_id" do
    it "renders not_found" do
      expect do
        get "/chat_channel_memberships/find_by_chat_channel_id", params: {}
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
