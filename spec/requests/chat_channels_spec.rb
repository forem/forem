require "rails_helper"

RSpec.describe "ChatChannels", type: :request do
  let(:user) { create(:user) }
  let(:test_subject) { create(:user) }
  let(:chat_channel) { create(:chat_channel) }
  let(:invite_channel) { create(:chat_channel, channel_type: "invite_only") }
  let(:direct_channel) { create(:chat_channel, channel_type: "direct", slug: "hello/#{user.username}") }

  before do
    sign_in user
    chat_channel.add_users([user])
  end

  describe "GET /connect" do
    context "logged in" do
      before do
        get "/connect"
      end

      it "has proper content" do
        expect(response.body).to include("DEV Connect is Beta ")
      end
    end

    context "logged in, visiting existing channel" do
      before do
        invite_channel.add_users [user]
        sign_in user
        get "/connect/#{invite_channel.slug}"
      end

      it "has proper content" do
        expect(response.body).to include("DEV Connect is Beta ")
      end
    end
  end

  describe "get /chat_channels?state=unopened" do
    it "returns unopened channels" do
      direct_channel.add_users [user]
      user.chat_channel_memberships.each do |m|
        m.has_unopened_messages = true
        m.save
      end
      sign_in user
      get "/chat_channels?state=unopened"
      expect(response.body).to include(direct_channel.slug)
    end
  end

  describe "get /chat_channels?state=pending" do
    it "returns pending channels" do
      pending_membership = ChatChannelMembership.create(chat_channel_id: invite_channel.id,
        user_id:user.id, status: "pending")
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
      pending_membership = ChatChannelMembership.create(chat_channel_id: invite_channel.id,
        user_id:user.id, status: "rejected")
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
        expect(response.status).to eq(200)
      end

      it "returns the channel" do
        expect(response).to render_template(:show)
      end
    end

    context "when request is invalid" do
      it "returns proper error message" do
        expect { get "/chat_channels/1200" }.to raise_error(ActionController::RoutingError)
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
      #slug should be taken
      post "/chat_channels",
      params: { chat_channel: { channel_name: "HEy hey hoho", slug: chat_channel.slug } },
      headers: { HTTP_ACCEPT: "application/json" }
      expect(response.body).to include("Slug has already been taken")
    end
  end

  describe "PUT /chat_channels/:id" do
    it "updates channel for valid user" do
      user.add_role(:super_admin)
      put "/chat_channels/#{chat_channel.id}",
      params: { chat_channel: { channel_name: "Hello Channel", slug: "hello-channelly" } },
      headers: { HTTP_ACCEPT: "application/json" }
      expect(ChatChannel.last.slug).to eq("hello-channelly")
    end
    it "dissallows invalid users" do
      expect do
        put "/chat_channels/#{chat_channel.id}",
        params: { chat_channel: { channel_name: "Hello Channel", slug: "hello-channelly" } },
        headers: { HTTP_ACCEPT: "application/json" }
      end.to raise_error(Pundit::NotAuthorizedError)
    end
    it "returns errors if channel is invalid" do
      #slug should be taken
      user.add_role(:super_admin)
      put "/chat_channels/#{chat_channel.id}",
      params: { chat_channel: { channel_name: "HEy hey hoho", slug: invite_channel.slug } },
      headers: { HTTP_ACCEPT: "application/json" }
      expect(response.body).to include("Slug has already been taken")
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
        user.add_role :super_admin
        sign_in user
        allow(Pusher).to receive(:trigger).and_return(true)
      end

      it "enforces chat_channel_params" do
        post "/chat_channels/#{chat_channel.id}/moderate",
          params: { chat_channel: { command: "/ban #{test_subject.username}" } }
        expect(response.status).to eq(200)
      end
      it "enforces chat_channel_params" do
        post "/chat_channels/#{chat_channel.id}/moderate",
          params: { chat_channel: { command: "/unban #{test_subject.username}" } }
        expect(response.status).to eq(200)
      end
    end
  end

  describe "POST /chat_channels/:id/open" do
    it "returns success" do
      post "/chat_channels/#{chat_channel.id}/open"
      expect(response.body).to include("success")
    end

    it "marks chat_channel_membership as opened" do
      post "/chat_channels/#{chat_channel.id}/open"
      expect(user.chat_channel_memberships.last.has_unopened_messages).to eq(false)
    end
  end
end
