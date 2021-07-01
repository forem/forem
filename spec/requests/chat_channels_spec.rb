require "rails_helper"

RSpec.describe "ChatChannels", type: :request do
  let(:user) { create(:user) }
  let(:user_open_inbox) do
    u = create(:user)
    u.setting.update(inbox_type: "open")
    u
  end
  let(:user_closed_inbox) { create(:user) }
  let(:test_subject) { create(:user) }
  let(:chat_channel) { create(:chat_channel) }
  let(:invite_channel) { create(:chat_channel, channel_type: "invite_only") }
  let(:direct_channel) do
    create(:chat_channel, channel_type: "direct", slug: "hello/#{user.username}")
  end

  before do
    sign_in user
    chat_channel.add_users([user])
    chat_channel.chat_channel_memberships.update(status: "active")
  end

  describe "GET /connect" do
    context "when logged in" do
      before do
        get "/connect"
      end

      it "has proper content" do
        expect(response.body).to include("chat-page-wrapper")
      end
    end

    context "when logged in and visiting existing channel" do
      before do
        invite_channel.add_users [user]
        sign_in user
        get "/connect/#{invite_channel.slug}"
      end

      it "has proper content" do
        expect(response.body).to include("chat-page-wrapper")
      end
    end

    context "when active membership is pending" do
      before do
        invite_channel.add_users [user]
        invite_channel.chat_channel_memberships.last.update(status: "pending")

        sign_in user
        get "/connect/#{invite_channel.slug}"
      end

      it "have no active channel" do
        expect(response).not_to(redirect_to(connect_path(invite_channel.slug)))
        # The slug will be rendered by the mobile runtime banner because the
        # request is made directly to "/connect/#{invite_channel.slug}", that's
        # why we can't simply check that the slug isn't included in
        # `response.body`. We can check using a regex to make sure the channel
        # doesn't exist within the chat (after chat DOM element appears but also
        # before the runtime banner starts).
        expect(response.body).not_to match(/<div id="chat".*#{invite_channel.slug}.*<div class="runtime-banner"/)
      end
    end

    context "when logged in and chat channel doesnt exist" do
      it "renders chat page" do
        sign_in user
        get "/connect/@#{user.username}"
        expect(response.status).to eq(200)
        expect(response.body).to include("chat-page-wrapper")
      end
    end
  end

  describe "get /chat_channels?state=unopened" do
    it "returns unopened channels" do
      direct_channel.add_users [user]
      user.chat_channel_memberships.each { |m| m.update(has_unopened_messages: true) }
      sign_in user
      get "/chat_channels?state=unopened"
      expect(response.body).to include(direct_channel.slug)
    end
  end

  describe "get /chat_channels?state=joining_request" do
    it "returns joining request channels" do
      membership = ChatChannelMembership.create(chat_channel_id: invite_channel.id, user_id: user.id,
                                                status: "joining_request", role: "mod")
      membership.chat_channel.update(discoverable: true)
      sign_in user
      get "/chat_channels?state=joining_request"
      expect(response.body).to include("\"member_name\":\"#{membership.user.username}\"")
    end
  end

  describe "get /chat_channels?state=unopened_ids" do
    it "returns unopened chat channel ids" do
      direct_channel.add_users [user]
      user.chat_channel_memberships.each { |m| m.update(has_unopened_messages: true) }
      sign_in user
      get "/chat_channels?state=unopened_ids"
      expect(response.body).to include(direct_channel.id.to_s)
      expect(response.body).to include("unopened_ids")
    end

    it "does not return chat channel ids if not signed in" do
      direct_channel.add_users [user]
      user.chat_channel_memberships.each { |m| m.update(has_unopened_messages: true) }
      sign_out user
      expect do
        get "/chat_channels?state=unopened_ids"
      end.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  describe "get /chat_channels?state=pending" do
    it "returns pending channels" do
      ChatChannelMembership.create(chat_channel_id: invite_channel.id, user_id: user.id, status: "pending")
      sign_in user
      get "/chat_channels?state=pending"
      expect(response.body).to include(invite_channel.slug)
    end

    it "returns no pending channels if no invites" do
      sign_in user
      get "/chat_channels?state=pending"
      expect(response.body).not_to include(invite_channel.slug)
    end

    it "returns no pending channels if not pending" do
      ChatChannelMembership.create(chat_channel_id: invite_channel.id, user_id: user.id, status: "rejected")
      sign_in user
      get "/chat_channels?state=pending"
      expect(response.body).not_to include(invite_channel.slug)
    end
  end

  describe "GET /chat_channels/:id" do
    context "when request is valid" do
      before do
        get "/chat_channels/#{chat_channel.id}", headers: { HTTP_ACCEPT: "application/json" }
      end

      it "returns 200" do
        expect(response).to have_http_status(:ok)
      end

      it "returns the channel" do
        result = { messages: [], chatChannelId: chat_channel.id }.to_json
        expect(response.body).to eq(result)
      end
    end

    context "when request is invalid" do
      it "returns proper error message" do
        expect { get "/chat_channels/1200" }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "POST /chat_channels" do
    it "creates chat_channel for current user" do
      post "/chat_channels",
           params: { chat_channel: { channel_name: "Hello Channel", slug: "hello-channel" } },
           headers: { HTTP_ACCEPT: "application/json" }
      expect(ChatChannel.last.slug).to eq("hello-channel")
      expect(ChatChannel.last.active_users).to include(user)
    end

    it "returns errors if channel is invalid" do
      # slug should be taken
      post "/chat_channels",
           params: { chat_channel: { channel_name: "HEy hey hoho", slug: chat_channel.slug } },
           headers: { HTTP_ACCEPT: "application/json" }
      expect(response.body).to include("Slug has already been taken")
    end
  end

  describe "PUT /chat_channels/:id" do
    it "updates channel for valid user" do
      user.add_role(:super_admin)
      membership = chat_channel.chat_channel_memberships.where(user_id: user.id).last
      membership.update(role: "mod")
      put "/chat_channels/#{chat_channel.id}",
          params: { chat_channel: { channel_name: "Hello Channel", slug: "hello-channelly" } },
          headers: { HTTP_ACCEPT: "application/json" }
      expect(ChatChannel.last.slug).to eq("hello-channelly")
      expect(response).to(redirect_to(edit_chat_channel_membership_path(membership.id)))
    end

    it "dissallows invalid users" do
      expect do
        put "/chat_channels/#{chat_channel.id}",
            params: { chat_channel: { channel_name: "Hello Channel", slug: "hello-channelly" } },
            headers: { HTTP_ACCEPT: "application/json" }
      end.to raise_error(Pundit::NotAuthorizedError)
    end

    it "returns errors if channel is invalid" do
      # slug should be taken
      user.add_role(:super_admin)
      membership = chat_channel.chat_channel_memberships.where(user_id: user.id).last
      membership.update(role: "mod")
      put "/chat_channels/#{chat_channel.id}",
          params: { chat_channel: { channel_name: "HEy hey hoho", slug: invite_channel.slug } },
          headers: { HTTP_ACCEPT: "application/json" }
      expect(response).to(redirect_to(edit_chat_channel_membership_path(membership.id)))
    end
  end

  describe "PATCH /chat_channels/update_channel/:id" do
    it "updates chat channel for valid user" do
      user.add_role(:super_admin)
      membership = chat_channel.chat_channel_memberships.where(user_id: user.id).last
      membership.update(role: "mod")
      patch "/chat_channels/update_channel/#{chat_channel.id}", params: {
        chat_channel: {
          channel_name: "Hello Channel",
          slug: "hello-channelly"
        }
      }

      expect(response.status).to eq(200)
      expect(ChatChannel.last.slug).to eq("hello-channelly")
    end

    it "un-authorized users" do
      expect do
        patch "/chat_channels/update_channel/#{chat_channel.id}", params: {
          chat_channel: {
            channel_name: "Hello Channel",
            slug: "hello-channelly"
          }
        }
      end.to raise_error(Pundit::NotAuthorizedError)
    end

    it "returns errors if channel is invalid" do
      # slug should be taken
      user.add_role(:super_admin)
      membership = chat_channel.chat_channel_memberships.where(user_id: user.id).last
      membership.update(role: "mod")
      patch "/chat_channels/update_channel/#{chat_channel.id}", params: {
        chat_channel: { channel_name: "Hello Channel", slug: invite_channel.slug }
      }
      expect(ChatChannel.last.slug).not_to eq("hello-channelly")
    end
  end

  describe "POST /chat_channels/:id/moderate" do
    it "raises NotAuthorizedError if user is not logged in" do
      expect do
        post "/chat_channels/#{chat_channel.id}/moderate",
             params: { chat_channel: { command: "/ban huh" } },
             headers: { HTTP_ACCEPT: "application/json" }
      end.to raise_error(Pundit::NotAuthorizedError)
    end

    it "raises NotAuthorizedError if user is logged in but not authorized" do
      sign_in user
      expect do
        post "/chat_channels/#{chat_channel.id}/moderate",
             params: { chat_channel: { command: "/ban huh" } },
             headers: { HTTP_ACCEPT: "application/json" }
      end.to raise_error(Pundit::NotAuthorizedError)
    end

    context "when user is logged-in and authorized" do
      before do
        user.add_role(:codeland_admin)
        chat_channel.add_users([user, test_subject])
        sign_in user
        allow(Pusher).to receive(:trigger).and_return(true)
      end

      it "enforces chat_channel_params on ban" do
        post "/chat_channels/#{chat_channel.id}/moderate",
             params: { chat_channel: { command: "/ban #{test_subject.username}" } }
        expect(response.status).to eq(200)
      end

      it "enforces chat_channel_params on unban" do
        post "/chat_channels/#{chat_channel.id}/moderate",
             params: { chat_channel: { command: "/unban #{test_subject.username}" } }
        expect(response.status).to eq(200)
      end
    end
  end

  describe "POST /chat_channels/:id/open" do
    it "returns success" do
      allow(Pusher).to receive(:trigger).and_return(true)
      post "/chat_channels/#{chat_channel.id}/open"
      expect(response.body).to include("success")
    end

    it "marks chat_channel_membership as opened" do
      allow(Pusher).to receive(:trigger).and_return(true)
      post "/chat_channels/#{chat_channel.id}/open"
      expect(user.chat_channel_memberships.last.has_unopened_messages).to eq(false)
    end
  end

  describe "POST /chat_channels/create_chat" do
    it "creates open chat with user who has open inbox" do
      post "/chat_channels/create_chat",
           params: { user_id: user_open_inbox.id }
      expect(response.status).to eq(200)
    end

    it "does not create for non-open inbox user" do
      post "/chat_channels/create_chat",
           params: { user_id: user_closed_inbox.id }
      expect(response.status).to eq(400)
    end

    it "creates ensures new chat channel is created for targeted user" do
      post "/chat_channels/create_chat",
           params: { user_id: user_open_inbox.id }
      expect(user_open_inbox.chat_channel_memberships.size).to eq(1)
    end

    it "returns error message if create_with_users fails" do
      allow(ChatChannels::CreateWithUsers).to receive(:call).and_raise(StandardError.new("Blocked"))
      post "/chat_channels/create_chat",
           params: { user_id: user_open_inbox.id }
      expect(response.parsed_body["message"]).to eq("Blocked")
    end
  end

  describe "POST /chat_channels/block_chat" do
    it "blocks successfully when user has permissions" do
      direct_channel.add_users [user]
      post "/chat_channels/block_chat",
           params: { chat_id: direct_channel.id }
      expect(response.status).to eq(200)
    end

    it "makes chat channel have status of blocked" do
      direct_channel.add_users [user]
      post "/chat_channels/block_chat",
           params: { chat_id: direct_channel.id }
      expect(direct_channel.reload.status).to eq("blocked")
    end

    it "does not block when channel is open" do
      expect { post "/chat_channels/block_chat", params: { chat_id: chat_channel.id } }
        .to raise_error(Pundit::NotAuthorizedError)
    end

    it "does not block when user does not have permissions" do
      expect { post "/chat_channels/block_chat", params: { chat_id: direct_channel.id } }
        .to raise_error(Pundit::NotAuthorizedError)
    end
  end

  describe "GET /api/chat_channels/:id/channel_info" do
    def channel_info_request(chat_channel_id)
      get chat_channel_info_path(chat_channel_id),
          headers: { HTTP_ACCEPT: "application/json" }
    end

    context "when errors occur" do
      it "returns not auhorized when the user is not user signed in" do
        sign_out user

        channel_info_request(chat_channel.id)

        expect(response).to have_http_status(:not_found)
      end

      it "returns not found if the user is not a member of the channel" do
        chat_channel.remove_user(user)

        channel_info_request(chat_channel.id)

        expect(response).to have_http_status(:not_found)
      end

      it "returns not found if channel id does not exist" do
        channel_info_request("invalid")

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when no errors occur" do
      before do
        channel_info_request(chat_channel.id)
      end

      it "returns ok if user is a member of the channel" do
        expect(response).to have_http_status(:ok)
      end

      it "returns chat channel with the correct json representation", :aggregate_failures do
        response_channel = response.parsed_body
        expect(response_channel.keys).to match_array(
          %w[type_of id description channel_name username channel_users channel_mod_ids pending_users_select_fields],
        )

        %w[id description channel_name channel_mod_ids].each do |attr|
          expect(response_channel[attr]).to eq(chat_channel.public_send(attr))
        end

        expect(response_channel["username"]).to eq(chat_channel.channel_name)
        expect(response_channel["pending_users_select_fields"]).to be_empty
      end

      it "returns the correct channel users representation" do
        response_channel_users = response.parsed_body["channel_users"]

        expected_last_opened_at = Time.zone.parse(response_channel_users[user.username]["last_opened_at"]).to_i
        response_user = response_channel_users[user.username]

        expect(response_user["profile_image"]).to eq(Images::Profile.call(user.profile_image_url, length: 90))
        expect(response_user["darker_color"]).to eq(user.decorate.darker_color)
        expect(response_user["name"]).to eq(user.name)
        expect(expected_last_opened_at).to eq(user.chat_channel_memberships.last.last_opened_at.to_i)
        expect(response_user["username"]).to eq(user.username)
        expect(response_user["id"]).to eq(user.id)
      end

      it "returns the correct pending users select fields representation" do
        # add another user's pending membership
        pending_user = create(:user)
        chat_channel.add_users(pending_user)
        pending_user.chat_channel_memberships.last.update(status: :pending)

        channel_info_request(chat_channel.id)

        response_pending_user_select_fields = response.parsed_body["pending_users_select_fields"].first

        expected_updated_at = Time.zone.parse(response_pending_user_select_fields["updated_at"]).to_i

        expect(response_pending_user_select_fields["id"]).to eq(pending_user.id)
        expect(response_pending_user_select_fields["name"]).to eq(pending_user.name)
        expect(expected_updated_at).to eq(pending_user.updated_at.to_i)
        expect(response_pending_user_select_fields["username"]).to eq(pending_user.username)
      end
    end
  end

  describe "POST /create_channel" do
    it "create channel by mod users only" do
      user.add_role(:tag_moderator)
      post "/create_channel", params: {
        chat_channel: {
          channel_name: "dummy test",
          invitation_usernames: ""
        }
      }
      expect(response.status).to eq(200)
      expect(response.parsed_body["success"]).to eq(true)
    end

    it "when non mod user logged in" do
      expect do
        post "/create_channel", params: {
          chat_channel: {
            channel_name: "dummy test",
            invitation_usernames: ""
          }
        }
      end.to raise_error(Pundit::NotAuthorizedError)
    end
  end
end
