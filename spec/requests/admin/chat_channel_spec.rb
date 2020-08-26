require "rails_helper"

RSpec.describe "/admin/chat_channels", type: :request do
  let(:user) { create(:user) }
  let(:chat_channel) { create(:chat_channel) }

  describe "POST /chat_channels" do
    around { |example| perform_enqueued_jobs(&example) }

    it "creates chat_channel for with users as moderator" do
      user.add_role(:super_admin)
      sign_in user
      expect do
        post "/admin/chat_channels",
             params: { chat_channel: { channel_name: "Hello Channel", usernames_string: user.username } },
             headers: { HTTP_ACCEPT: "application/json" }
      end.to change(ActionMailer::Base.deliveries, :length)
      expect(ChatChannel.last.channel_name).to eq("Hello Channel")
      expect(ChatChannel.last.pending_users).to include(user)
    end
  end

  describe "PATCH /chat_channels" do
    it "adds the user as a member to the chat channel" do
      user.add_role(:super_admin)
      second_user = create(:user)
      sign_in user
      patch "/admin/chat_channels/#{chat_channel.id}",
            params: { chat_channel: { usernames_string: second_user.username } },
            headers: { HTTP_ACCEPT: "application/json" }
      expect(second_user.chat_channel_memberships.last).not_to be_blank
      expect(second_user.chat_channel_memberships.last.role).to eq "member"
    end
  end

  describe "DELETE /admin/chat_channels/remove_user/:id" do
    it "removes the user from the chat channel" do
      user.add_role(:super_admin)
      sign_in user
      chat_channel.invite_users(users: user)

      delete "/admin/chat_channels/#{chat_channel.id}/remove_user",
             params: { chat_channel: { username_string: user.username } }
      expect(user.chat_channel_memberships.count).to eq 0
      expect(chat_channel.users.count).to eq 0
    end
  end

  describe "DELETE /admin/chat_channels/:id" do
    it "deletes the chat channel when it has no users" do
      user.add_role(:super_admin)
      sign_in user

      delete "/admin/chat_channels/#{chat_channel.id}"
      expect { ChatChannel.find(chat_channel.id) }.to raise_exception(ActiveRecord::RecordNotFound)
    end
  end
end
