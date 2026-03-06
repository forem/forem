require "rails_helper"

RSpec.describe "AgentSessions#show" do
  let(:owner) { create(:user) }
  let(:other_user) { create(:user) }
  let(:admin) { create(:user, :super_admin) }
  let(:curated_data) do
    {
      "messages" => [
        { "index" => 0, "role" => "user", "content" => [{ "type" => "text", "text" => "Hello" }] },
        { "index" => 1, "role" => "assistant", "content" => [{ "type" => "text", "text" => "Hi" }] },
      ],
      "metadata" => { "tool_name" => "claude_code", "total_messages" => 2 }
    }
  end
  let(:agent_session) do
    AgentSession.create!(user: owner, title: "My Session", tool_name: "claude_code", curated_data: curated_data)
  end

  describe "GET /agent_sessions/:slug" do
    context "when published" do
      before { agent_session.update!(published: true) }

      it "is accessible without login" do
        get agent_session_path(agent_session)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("My Session")
      end

      it "shows author attribution to public viewers" do
        get agent_session_path(agent_session)
        expect(response.body).to include(owner.username)
      end

      it "does not show owner controls to public viewers" do
        get agent_session_path(agent_session)
        expect(response.body).not_to include("All Sessions")
        expect(response.body).not_to include("Curate")
      end

      it "shows owner controls when owner is signed in" do
        sign_in owner
        get agent_session_path(agent_session)
        expect(response.body).to include("All Sessions")
        expect(response.body).to include("Curate")
      end

      it "shows share link to owner" do
        sign_in owner
        get agent_session_path(agent_session)
        expect(response.body).to include("curator-meta-share-input")
        expect(response.body).to include("Copy link")
      end

      it "does not show embed copy snippets to non-owners" do
        sign_in other_user
        get agent_session_path(agent_session)
        expect(response.body).not_to include("agent_session #{agent_session.slug}")
      end
    end

    context "when unpublished" do
      it "returns 404 page for unauthenticated users" do
        get agent_session_path(agent_session)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to include("not available")
      end

      it "returns 404 page for non-owner users" do
        sign_in other_user
        get agent_session_path(agent_session)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to include("not available")
      end

      it "is accessible by owner" do
        sign_in owner
        get agent_session_path(agent_session)
        expect(response).to have_http_status(:ok)
      end

      it "is accessible by admin" do
        sign_in admin
        get agent_session_path(agent_session)
        expect(response).to have_http_status(:ok)
      end
    end

    context "when session does not exist" do
      it "returns 404 page for non-existent slug" do
        get "/agent_sessions/totally-fake-slug"
        expect(response).to have_http_status(:not_found)
        expect(response.body).to include("not available")
      end
    end
  end
end
