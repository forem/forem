require "rails_helper"

RSpec.describe "ChatChannelMemberships", type: :request do
  let(:user) { create(:user) }
  let(:second_user) { create(:user) }
  let(:chat_channel) { create(:chat_channel) }

  before do
    sign_in user
    chat_channel.add_users([user])
  end

  describe "GET /chat_channel_info" do
    context "when chat channel membership role is mod" do
      before do
        user.add_role(:super_admin)

        membership = ChatChannelMembership.find_by(chat_channel_id: chat_channel.id, user_id: user.id)
        get "/chat_channel_memberships/chat_channel_info/#{membership.id}"
      end

      it "return all details of chat channel" do
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["result"].keys).to eq(%w[chat_channel memberships current_membership])
      end
    end

    context "when membership role is member" do
      before do
        sign_in second_user
        chat_channel.add_users([second_user])

        membership = ChatChannelMembership.find_by(chat_channel_id: chat_channel.id, user_id: second_user.id)
        get "/chat_channel_memberships/chat_channel_info/#{membership.id}"
      end

      it "return only channel info and current membership" do
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)["result"].keys).to eq(%w[chat_channel memberships current_membership])
        expect(JSON.parse(response.body)["result"]["memberships"]["pending"].length).to eq(0)
        expect(JSON.parse(response.body)["result"]["memberships"]["requested"].length).to eq(0)
      end
    end
  end

  describe "POST/ Send Invitation fot chat channel" do
    context "when chat channel membership role is mod" do
      before do
        user.add_role(:super_admin)

        post "/chat_channel_memberships/create_membership_request", params: {
          chat_channel_membership: {
            invitation_usernames: second_user.username.to_s,
            chat_channel_id: chat_channel.id
          }
        }
      end

      it "Send invitation to user" do
        expect(response.status).to eq(200)
      end
    end

    context "when chat channel membership role is member" do
      before do
        sign_in second_user
        chat_channel.add_users([second_user])

        post "/chat_channel_memberships/create_membership_request", params: {
          chat_channel_membership: {
            invitation_usernames: "test2031",
            chat_channel_id: chat_channel.id
          }
        }
      end

      it "user not authorized" do
        expect(response.status).to eq(401)
      end
    end
  end

  describe "POST/ remove_membership" do
    context "when the user is super admin" do
      it "remove the user from chat channel" do
        allow(Pusher).to receive(:trigger).and_return(true)

        user.add_role(:super_admin)
        membership = ChatChannelMembership.find_by(chat_channel_id: chat_channel.id, user_id: user.id)

        post "/chat_channel_memberships/remove_membership", params: {
          chat_channel_id: chat_channel.id,
          membership_id: membership.id
        }

        expect(response.status).to eq(200)
        expect(membership.reload.status).to eq("removed_from_channel")
      end
    end

    context "when user is chat channel membership role is mod" do
      it "remove the user from chat channel" do
        allow(Pusher).to receive(:trigger).and_return(true)
        membership = chat_channel.chat_channel_memberships.find_by(user_id: user.id)
        membership.update(role: "mod")

        post "/chat_channel_memberships/remove_membership", params: {
          chat_channel_id: chat_channel.id,
          membership_id: membership.id
        }

        expect(response.status).to eq(200)
        expect(membership.reload.status).to eq("removed_from_channel")
      end
    end

    context "when user chat channel membership role is member" do
      it "user is not unauthorized" do
        sign_in second_user
        membership = ChatChannelMembership.last
        post "/chat_channel_memberships/remove_membership", params: {
          chat_channel_id: chat_channel.id,
          membership_id: membership.id
        }

        expect(response.status).to eq(401)
      end
    end
  end

  describe "PUT /chat_channel_memberships/:id" do
    before do
      user.add_role(:super_admin)
      post "/chat_channel_memberships/create_membership_request", params: {
        chat_channel_membership: {
          invitation_usernames: second_user.username.to_s,
          chat_channel_id: chat_channel.id
        }
      }
    end

    context "when second user accept invitation" do
      it "sets chat channl membership status to rejected" do
        allow(Pusher).to receive(:trigger).and_return(true)
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
        allow(Pusher).to receive(:trigger).and_return(true)
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
      it "unauthorized" do
        membership = ChatChannelMembership.last
        put "/chat_channel_memberships/#{membership.id}", params: {
          chat_channel_membership: { user_action: "accept" }
        }

        expect(response.status).to eq(401)
      end
    end
  end

  describe "PATCH/ update_membership" do
    context "when user is logged in" do
      it "update the notification status" do
        membership = ChatChannelMembership.find_by(chat_channel_id: chat_channel.id, user_id: user.id)
        membership.update(show_global_badge_notification: false)
        patch "/chat_channel_memberships/update_membership/#{membership.id}", params: {
          chat_channel_membership: {
            show_global_badge_notification: true
          }
        }

        expect(response.status).to eq(200)
        expect(membership.reload.show_global_badge_notification).to eq(true)
      end
    end

    context "when user is not logged in" do
      it "not found membership" do
        patch "/chat_channel_memberships/update_membership/", params: {
          chat_channel_membership: {
            show_global_badge_notification: true
          }
        }

        expect(response.status).to eq(404)
      end
    end
  end

  describe "POST/ /leave_membership/:id" do
    context "when user is logged in" do
      it "leaves chat channel" do
        allow(Pusher).to receive(:trigger).and_return(true)
        chat_channel.add_users([second_user])
        membership = ChatChannelMembership.last

        sign_in second_user

        patch "/chat_channel_memberships/leave_membership/#{membership.id}"

        expect(response.status).to eq(200)
        expect(membership.reload.status).to eq("left_channel")
      end
    end

    context "when user is not logged in" do
      it "unauthorized user" do
        chat_channel.add_users([second_user])
        membership = ChatChannelMembership.last
        membership_status = membership.status
        patch "/chat_channel_memberships/leave_membership/#{membership.id}"

        expect(response.status).to eq(401)
        expect(membership.reload.status).to eq(membership_status)
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
        get "/chat_channel_memberships/find_by_chat_channel_id", params: {}
        expect(response.status).to eq(404)
      end
    end
  end

  describe "POST /chat_channel_memberships/add_membership" do
    context "when user is moderator of channel" do
      it "adds requested member to join closed channel" do
        allow(Pusher).to receive(:trigger).and_return(true)
        channel = ChatChannel.first
        membership = ChatChannelMembership.last
        membership.update(status: "joining_request")
        membership.update(role: "mod")
        post "/chat_channel_memberships/add_membership", params: {
          membership_id: membership.id,
          chat_channel_id: channel.id,
          chat_channel_membership: {
            user_action: "accept"
          }
        }
        expect(ChatChannelMembership.find(membership.id).status).to eq("active")
        expect(response).to(redirect_to(chat_channel_memberships_path))
      end
    end

    context "when user is member of channel" do
      it "User not authorize" do
        channel = ChatChannel.first
        membership = ChatChannelMembership.last
        membership.update(status: "joining_request")
        post "/chat_channel_memberships/add_membership", params: {
          membership_id: membership.id,
          chat_channel_id: channel.id,
          chat_channel_membership: {
            user_action: "accept"
          }
        }

        expect(ChatChannelMembership.find(membership.id).status).to eq("joining_request")
        expect(response.status).to eq(401)
      end
    end
  end

  describe "POST /join_chat_channel" do
    let(:chat_channel_membership) do
      {
        chat_channel_id: chat_channel.id
      }
    end

    before do
      allow(Pusher).to receive(:trigger).and_return(true)
      sign_in second_user
      post "/join_chat_channel", params: { chat_channel_membership: chat_channel_membership }
    end

    context "when user was not member of closed channel" do
      it "requested to join closed channel" do
        expect(ChatChannelMembership.last.status).to eq("joining_request")
        expect(response.status).to eq(200)
      end

      it "returns in json" do
        expect(response.media_type).to eq("application/json")
      end
    end

    context "when user was a member of channel, and than left channel" do
      it "requested to join closed channel" do
        ChatChannelMembership.create(chat_channel_id: chat_channel.id, user_id: second_user.id, status: "left_channel")
        expect(ChatChannelMembership.last.status).to eq("joining_request")
        expect(response.status).to eq(200)
      end

      it "returns in json" do
        expect(response.media_type).to eq("application/json")
      end
    end
  end
end
