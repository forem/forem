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
        get "/chat_channel_memberships/chat_channel_info/#{membership.id}", as: :json
      end

      it "return all details of chat channel" do
        expect(response.status).to eq(200)
        expect(response.parsed_body["result"].keys).to eq(%w[chat_channel memberships current_membership
                                                             invitation_link])
      end
    end

    context "when membership role is member" do
      before do
        sign_in second_user
        chat_channel.add_users([second_user])

        membership = ChatChannelMembership.find_by(chat_channel_id: chat_channel.id, user_id: second_user.id)
        get "/chat_channel_memberships/chat_channel_info/#{membership.id}", as: :json
      end

      it "return only channel info and current membership" do
        expect(response.status).to eq(200)
        expect(response.parsed_body["result"].keys).to eq(%w[chat_channel memberships current_membership
                                                             invitation_link])
        expect(response.parsed_body["result"]["memberships"]["pending"].length).to eq(0)
        expect(response.parsed_body["result"]["memberships"]["requested"].length).to eq(0)
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

    it "does not send pusher notifications" do
      allow(Pusher).to receive(:trigger)

      user.add_role(:super_admin)
      membership = ChatChannelMembership.find_by(chat_channel_id: chat_channel.id, user_id: user.id)

      post "/chat_channel_memberships/remove_membership", params: {
        chat_channel_id: chat_channel.id,
        membership_id: membership.id
      }

      expect(Pusher).not_to have_received(:trigger)
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

  describe "PATCH /leave_membership/:id" do
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

      it "does not send Pusher notifications" do
        allow(Pusher).to receive(:trigger)
        chat_channel.add_users([second_user])
        membership = ChatChannelMembership.last

        sign_in second_user

        patch "/chat_channel_memberships/leave_membership/#{membership.id}"

        expect(Pusher).not_to have_received(:trigger)
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

  describe "GET /request_details" do
    context "when user signed in" do
      it "return success" do
        sign_in second_user
        ChatChannelMembership.create(user_id: second_user.id, chat_channel_id: chat_channel.id, status: "pending")
        get "/channel_request_info", as: :json

        expect(response.status).to eq(200)
        expect(response.parsed_body["result"].keys).to eq(%w[channel_joining_memberships user_joining_requests])
      end
    end

    context "when user is logged out" do
      it "return not authorized" do
        sign_out second_user
        get "/channel_request_info", as: :json
      end
    end
  end

  describe "PATCH /update_membership_role" do
    before do
      user.add_role(:super_admin)
      chat_channel.add_users([second_user])
    end

    context "when user role is member" do
      it "update the membership role to mod" do
        allow(Pusher).to receive(:trigger).and_return(true)
        membership = ChatChannelMembership.find_by(chat_channel_id: chat_channel.id, user_id: second_user.id)

        patch "/chat_channel_memberships/update_membership_role/#{chat_channel.id}", params: {
          chat_channel_membership: {
            membership_id: membership.id,
            role: "mod"
          }
        }
        expect(response.status).to eq(200)
        expect(membership.reload.role).to eq("mod")
      end
    end

    context "when user is mod" do
      it "update the membership role to member" do
        allow(Pusher).to receive(:trigger).and_return(true)
        membership = ChatChannelMembership.find_by(chat_channel_id: chat_channel.id, user_id: user.id)

        patch "/chat_channel_memberships/update_membership_role/#{chat_channel.id}", params: {
          chat_channel_membership: {
            membership_id: membership.id,
            role: "member"
          }
        }

        expect(response.status).to eq(200)
        expect(membership.reload.role).to eq("member")
      end
    end

    context "when there is no channel id" do
      it "channel not found" do
        membership = ChatChannelMembership.find_by(chat_channel_id: chat_channel.id, user_id: second_user.id)

        patch "/chat_channel_memberships/update_membership_role/", params: {
          chat_channel_membership: {
            membership_id: membership.id,
            role: "member"
          }
        }

        expect(response.status).to eq(404)
        expect(membership.reload.role).to eq("member")
      end
    end
  end

  describe "GET /join_channel_invitation" do
    context "when user is not member" do
      it "render the page" do
        allow(Pusher).to receive(:trigger).and_return(true)
        sign_in second_user
        chat_channel.update(discoverable: true)

        get "/join_channel_invitation/#{chat_channel.slug}"

        expect(response.status).to eq(200)
      end
    end

    context "when user is not logged-in" do
      it "not allowed to create membership" do
        sign_out second_user

        get "/join_channel_invitation/#{chat_channel.slug}"
        expect(response.status).to eq(302)
      end
    end
  end

  describe "POST /joining_invitation_response" do
    context "when user accept the request" do
      it "will create membership" do
        allow(Pusher).to receive(:trigger).and_return(true)

        sign_in second_user
        chat_channel.update(discoverable: true)

        post "/joining_invitation_response", params: {
          user_action: "accept",
          chat_channel_id: chat_channel.id
        }
        membership = ChatChannelMembership.last

        expect(response.status).to eq(302)
        expect(membership.user_id).to eq(second_user.id)
      end
    end

    context "when user decline the request" do
      it "will not create the membership" do
        sign_in second_user
        chat_channel.update(discoverable: true)

        post "/joining_invitation_response", params: {
          user_action: "decline",
          chat_channel_id: chat_channel.id
        }

        membership = ChatChannelMembership.last

        expect(response.status).to eq(302)
        expect(membership.user_id).not_to eq(second_user.id)
      end
    end
  end
end
