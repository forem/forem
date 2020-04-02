require "rails_helper"

RSpec.describe "ChatChannelMemberships", type: :request do
  let(:user) { create(:user) }
  let(:second_user) { create(:user) }
  let(:chat_channel) { create(:chat_channel) }

  before do
    sign_in user
    chat_channel.add_users([user])
  end

  describe "GET /chat_channel_memberships" do
    context "when pending invitations exists" do
      before do
        user.add_role(:super_admin)
        post "/chat_channel_memberships", params: {
          chat_channel_membership: {
            invitation_usernames: second_user.username.to_s,
            chat_channel_id: chat_channel.id
          }
        }
      end

      it "shows chat_channel_memberships list pending invitation" do
        sign_in second_user
        get "/chat_channel_memberships"
        expect(response.body).to include "Pending Invitations"
        expect(response.body).to include chat_channel.channel_name.to_s
      end
    end

    context "when no pending invitation" do
      it "shows chat_channel_memberships list pending invitation" do
        sign_in second_user
        get "/chat_channel_memberships"
        expect(response.body).to include "You have no pending invitations"
      end
    end
  end

  describe "GET /chat_channel_memberships/find_by_chat_channel_id" do
    context "when user is logged in" do
      before do
        chat_channel.add_users([second_user])
      end

      it "returns chat channel membership details" do
        sign_in second_user
        get "/chat_channel_memberships/find_by_chat_channel_id", params: { chat_channel_id: chat_channel.id }
        expected_keys = %w[id status chat_channel_id last_opened_at channel_text
                           channel_last_message_at channel_status channel_username
                           channel_type channel_name channel_image
                           channel_modified_slug channel_messages_count]
        expect(response.parsed_body.keys).to(match_array(expected_keys))
      end
    end

    context "when user is not logged in" do
      it "renders not_found" do
        expect do
          get "/chat_channel_memberships/find_by_chat_channel_id", params: {}
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "GET /chat_channel_memberships/:id/edit" do
    before do
      chat_channel.add_users([second_user])
    end

    let(:chat_channel_membership) { chat_channel.chat_channel_memberships.where(user_id: second_user.id).first }

    context "when user is not logged in" do
      it "raise Pundit::NotAuthorizedError" do
        expect do
          get "/chat_channel_memberships/#{chat_channel_membership.id}/edit"
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when user is logged in and channel id is wrong" do
      it "raise ActiveRecord::RecordNotFound" do
        sign_in second_user
        expect do
          get "/chat_channel_memberships/ERW/edit"
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when user is channel member" do
      it "allows user to view channel members" do
        sign_in second_user
        get "/chat_channel_memberships/#{chat_channel_membership.id}/edit"
        expect(response.body).to include("Members")
        expect(response.body).to include(user.username.to_s)
        expect(response.body).to include(second_user.username.to_s)
        expect(response.body).not_to include("Pending Invitations")
      end
    end

    context "when user is channel moderator" do
      it "allows user to view channel members" do
        sign_in second_user
        chat_channel_membership.update(role: "mod")
        get "/chat_channel_memberships/#{chat_channel_membership.id}/edit"
        expect(response.body).to include("Members")
        expect(response.body).to include(user.username.to_s)
        expect(response.body).to include(second_user.username.to_s)
        expect(response.body).to include("Pending Invitations")
        expect(response.body).to include("You are a channel mod")
      end
    end
  end

  describe "POST /chat_channel_memberships" do
    context "when user is super admin" do
      it "creates chat channel invitation" do
        user.add_role(:super_admin)
        expect do
          post "/chat_channel_memberships", params: {
            chat_channel_membership: {
              invitation_usernames: second_user.username.to_s,
              chat_channel_id: chat_channel.id
            }
          }
        end.to change { ChatChannelMembership.all.size }.by(1)
        expect(ChatChannelMembership.last.status).to eq("pending")
      end
    end

    context "when user is channel moderator, and invited user was a member of channel, and than left channel" do
      it "creates chat channel invitation" do
        chat_channel.chat_channel_memberships.where(user_id: user.id).update(role: "mod")
        ChatChannelMembership.create(chat_channel_id: chat_channel.id, user_id: second_user.id, status: "left_channel")
        post "/chat_channel_memberships", params: {
          chat_channel_membership: {
            invitation_usernames: second_user.username.to_s,
            chat_channel_id: chat_channel.id
          }
        }
        expect(ChatChannelMembership.last.status).to eq("pending")
      end
    end

    context "when user is channel moderator, invited user was not a member of channel" do
      it "creates chat channel invitation" do
        chat_channel.chat_channel_memberships.where(user_id: user.id).update(role: "mod")
        chat_channel_members_count = ChatChannelMembership.all.size
        post "/chat_channel_memberships", params: {
          chat_channel_membership: {
            invitation_usernames: second_user.username.to_s,
            chat_channel_id: chat_channel.id
          }
        }
        expect(ChatChannelMembership.all.size).to eq(chat_channel_members_count + 1)
        expect(ChatChannelMembership.last.status).to eq("pending")
      end
    end

    context "when user is not authorized to add channel membership" do
      it "raise Pundit::NotAuthorizedError" do
        expect do
          post "/chat_channel_memberships", params: {
            chat_channel_membership: {
              invitation_usernames: second_user.username.to_s,
              chat_channel_id: chat_channel.id
            }
          }
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "PUT /chat_channel_memberships/:id" do
    before do
      user.add_role(:super_admin)
      post "/chat_channel_memberships", params: {
        chat_channel_membership: {
          invitation_usernames: second_user.username.to_s,
          chat_channel_id: chat_channel.id
        }
      }
    end

    context "when second user accept invitation" do
      it "sets chat channl membership status to rejected" do
        membership = ChatChannelMembership.last
        sign_in second_user
        put "/chat_channel_memberships/#{membership.id}", params: {
          chat_channel_membership: {
            user_action: "accept"
          }
        }
        expect(ChatChannelMembership.find(membership.id).status).to eq("active")
        expect(response).to(redirect_to(chat_channel_memberships_path))
      end
    end

    context "when second user rejects invitation" do
      it "sets chat channl membership status to rejected" do
        membership = ChatChannelMembership.last
        sign_in second_user
        put "/chat_channel_memberships/#{membership.id}", params: {
          chat_channel_membership: {
            user_action: "reject"
          }
        }
        expect(ChatChannelMembership.find(membership.id).status).to eq("rejected")
      end
    end

    context "when user not logged in" do
      it "raise Pundit::NotAuthorizedError" do
        membership = ChatChannelMembership.last
        expect do
          put "/chat_channel_memberships/#{membership.id}", params: {
            chat_channel_membership: { user_action: "accept" }
          }
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when user is unauthorized" do
      it "raise Pundit::NotAuthorizedError" do
        membership = ChatChannelMembership.last
        sign_in user
        expect do
          put "/chat_channel_memberships/#{membership.id}", params: {
            chat_channel_membership: { user_action: "accept" }
          }
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "DELETE /chat_channel_memberships/:id" do
    context "when user is logged in" do
      it "leaves chat channel" do
        chat_channel.add_users([second_user])
        membership = ChatChannelMembership.last
        sign_in second_user
        delete "/chat_channel_memberships/#{membership.id}", params: {}
        expect(ChatChannelMembership.find(membership.id).status).to eq("left_channel")
        expect(response).to(redirect_to(chat_channel_memberships_path))
      end
    end

    context "when user is not logged in" do
      it "raise Pundit::NotAuthorizedError" do
        chat_channel.add_users([second_user])
        membership = ChatChannelMembership.last
        expect do
          delete "/chat_channel_memberships/#{membership.id}", params: {}
        end.to(raise_error(Pundit::NotAuthorizedError))
      end
    end
  end

  describe "POST /chat_channel_memberships/remove_membership" do
    before do
      chat_channel.add_users([second_user])
    end

    context "when user is super admin" do
      it "removes member from channel" do
        user.add_role(:super_admin)
        membership = chat_channel.chat_channel_memberships.where(user_id: user.id).last
        removed_channel_membership = ChatChannelMembership.last
        post "/chat_channel_memberships/remove_membership", params: {
          chat_channel_id: chat_channel.id,
          membership_id: removed_channel_membership.id
        }
        expect(removed_channel_membership.reload.status).to eq("removed_from_channel")
        expect(response).to(redirect_to(edit_chat_channel_membership_path(membership.id)))
      end
    end

    context "when user is moderator of channel" do
      it "removes member from channel" do
        membership = chat_channel.chat_channel_memberships.where(user_id: user.id).last
        membership.update(role: "mod")
        removed_channel_membership = ChatChannelMembership.last
        post "/chat_channel_memberships/remove_membership", params: {
          chat_channel_id: chat_channel.id,
          membership_id: removed_channel_membership.id
        }
        expect(removed_channel_membership.reload.status).to eq("removed_from_channel")
        expect(response).to(redirect_to(edit_chat_channel_membership_path(membership.id)))
      end
    end

    context "when user is member of channel" do
      it "raise Pundit::NotAuthorizedError" do
        membership = ChatChannelMembership.last
        expect do
          post "/chat_channel_memberships/remove_membership", params: {
            chat_channel_id: chat_channel.id,
            membership_id: membership.id
          }
        end.to(raise_error(Pundit::NotAuthorizedError))
      end
    end
  end
end
