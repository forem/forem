require "rails_helper"

RSpec.describe "Api::V1::AgentSessions" do
  let(:user) { create(:user) }
  let(:api_secret) { create(:api_secret, user: user) }
  let(:headers) { { "content-type" => "application/json", "Accept" => "application/vnd.forem.api-v1+json" } }
  let(:auth_headers) { headers.merge({ "api-key" => api_secret.secret }) }

  let(:claude_code_jsonl) do
    [
      { type: "user", message: { role: "user", content: "Hello" }, uuid: "1",
        timestamp: "2025-01-01T00:00:00Z", sessionId: "s1" }.to_json,
      { type: "assistant", message: { role: "assistant", content: [{ type: "text", text: "Hi there" }] },
        uuid: "2", timestamp: "2025-01-01T00:00:01Z", sessionId: "s1" }.to_json,
    ].join("\n")
  end

  let(:normalized_data) do
    {
      "messages" => [
        { "index" => 0, "role" => "user", "content" => [{ "type" => "text", "text" => "Hello" }] },
        { "index" => 1, "role" => "assistant", "content" => [{ "type" => "text", "text" => "Hi there" }] },
      ],
      "metadata" => { "tool_name" => "claude_code", "total_messages" => 2 }
    }
  end

  describe "POST /api/agent_sessions" do
    it "returns 401 without authentication" do
      post api_agent_sessions_path,
           params: { title: "Test", body: claude_code_jsonl }.to_json,
           headers: headers
      expect(response).to have_http_status(:unauthorized)
    end

    it "creates a session from JSON body with auto-detection" do
      post api_agent_sessions_path,
           params: { title: "My Claude Session", body: claude_code_jsonl }.to_json,
           headers: auth_headers

      expect(response).to have_http_status(:created)
      json = response.parsed_body
      expect(json["title"]).to eq("My Claude Session")
      expect(json["tool_name"]).to eq("claude_code")
      expect(json["total_messages"]).to be >= 1
      expect(json["slug"]).to be_present
      expect(json["url"]).to include("/agent_sessions/")
      # Create response should be slim — no messages/curated_selections/slices
      expect(json).not_to have_key("messages")
      expect(json).not_to have_key("curated_selections")
      expect(json).not_to have_key("slices")
    end

    it "creates a session with explicit tool_name" do
      post api_agent_sessions_path,
           params: { title: "Codex Session", tool_name: "codex", body: claude_code_jsonl }.to_json,
           headers: auth_headers

      expect(response).to have_http_status(:created)
      json = response.parsed_body
      expect(json["tool_name"]).to eq("codex")
    end

    it "auto-generates title when not provided" do
      post api_agent_sessions_path,
           params: { body: claude_code_jsonl }.to_json,
           headers: auth_headers

      expect(response).to have_http_status(:created)
      json = response.parsed_body
      expect(json["title"]).to start_with("Session ")
    end

    it "returns 422 when body is missing" do
      post api_agent_sessions_path,
           params: { title: "No content" }.to_json,
           headers: auth_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to include("Missing session content")
    end

    it "returns 422 when content is too large" do
      large_body = "x" * (AgentSession::MAX_RAW_DATA_SIZE + 1)
      post api_agent_sessions_path,
           params: { title: "Too Big", body: large_body }.to_json,
           headers: auth_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to include("too large")
    end

    it "returns 422 for invalid tool_name" do
      post api_agent_sessions_path,
           params: { title: "Bad Tool", tool_name: "invalid_tool", body: claude_code_jsonl }.to_json,
           headers: auth_headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "assigns the session to the authenticated user" do
      post api_agent_sessions_path,
           params: { title: "My Session", body: claude_code_jsonl }.to_json,
           headers: auth_headers

      expect(response).to have_http_status(:created)
      session = AgentSession.last
      expect(session.user_id).to eq(user.id)
    end
  end

  describe "GET /api/agent_sessions" do
    before do
      AgentSession.create!(user: user, title: "Session A", tool_name: "claude_code", normalized_data: normalized_data)
      AgentSession.create!(user: user, title: "Session B", tool_name: "codex", normalized_data: normalized_data)
    end

    it "returns 401 without authentication" do
      get api_agent_sessions_path, headers: headers
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns the user's sessions" do
      get api_agent_sessions_path, headers: auth_headers
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json.size).to eq(2)
      expect(json.pluck("title")).to contain_exactly("Session A", "Session B")
    end

    it "does not return other users' sessions" do
      other_user = create(:user)
      AgentSession.create!(user: other_user, title: "Other Session", tool_name: "pi", normalized_data: normalized_data)

      get api_agent_sessions_path, headers: auth_headers
      json = response.parsed_body
      expect(json.pluck("title")).not_to include("Other Session")
    end
  end

  describe "GET /api/agent_sessions/:id" do
    let!(:agent_session) do
      AgentSession.create!(user: user, title: "My Session", tool_name: "claude_code", normalized_data: normalized_data)
    end

    it "returns 401 without authentication" do
      get api_agent_session_path(agent_session), headers: headers
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns the session by slug" do
      get api_agent_session_path(agent_session.slug), headers: auth_headers
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["title"]).to eq("My Session")
      expect(json["messages"]).to be_an(Array)
    end

    it "returns the session by id" do
      get api_agent_session_path(agent_session.id), headers: auth_headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["title"]).to eq("My Session")
    end

    it "returns 404 for another user's session" do
      other_user = create(:user)
      other_session = AgentSession.create!(
        user: other_user, title: "Other", tool_name: "codex", normalized_data: normalized_data,
      )
      get api_agent_session_path(other_session), headers: auth_headers
      expect(response).to have_http_status(:not_found)
    end
  end
end
