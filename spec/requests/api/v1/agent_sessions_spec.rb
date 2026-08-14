require "rails_helper"

RSpec.describe "Api::V1::AgentSessions" do
  let(:user) { create(:user) }
  let(:api_secret) { create(:api_secret, user: user) }
  let(:headers) { { "content-type" => "application/json", "Accept" => "application/vnd.forem.api-v1+json" } }
  let(:auth_headers) { headers.merge({ "api-key" => api_secret.secret }) }

  let(:curated_data) do
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
           params: { title: "Test", curated_data: curated_data.to_json }.to_json,
           headers: headers
      expect(response).to have_http_status(:unauthorized)
    end

    context "with curated_data" do
      it "creates a session from curated_data with s3_key" do
        post api_agent_sessions_path,
             params: { title: "S3 Session", tool_name: "claude_code",
                        curated_data: curated_data.to_json,
                        s3_key: "agent_sessions/#{user.id}/test.jsonl" }.to_json,
             headers: auth_headers

        expect(response).to have_http_status(:created)
        session = AgentSession.last
        expect(session.curated_data["messages"].size).to eq(2)
        expect(session.s3_key).to eq("agent_sessions/#{user.id}/test.jsonl")
      end

      it "creates a session from curated_data without s3_key" do
        post api_agent_sessions_path,
             params: { title: "No S3", tool_name: "claude_code",
                        curated_data: curated_data.to_json }.to_json,
             headers: auth_headers

        expect(response).to have_http_status(:created)
        session = AgentSession.last
        expect(session.curated_data["messages"].size).to eq(2)
        expect(session.s3_key).to be_nil
      end

      it "scrubs secrets in curated_data" do
        data_with_secret = curated_data.deep_dup
        data_with_secret["messages"][0]["content"][0]["text"] = "Token: ghp_abcdefghijklmnopqrstuvwxyz1234567890"

        post api_agent_sessions_path,
             params: { title: "Scrubbed", tool_name: "claude_code",
                        curated_data: data_with_secret.to_json }.to_json,
             headers: auth_headers

        expect(response).to have_http_status(:created)
        session = AgentSession.last
        text = session.curated_data["messages"].first["content"].first["text"]
        expect(text).to include("[REDACTED]")
      end

      it "rejects invalid curated_data" do
        post api_agent_sessions_path,
             params: { title: "Bad", curated_data: { "bad" => true }.to_json }.to_json,
             headers: auth_headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["error"]).to include("Missing required key: messages")
      end

      it "infers tool_name from metadata" do
        post api_agent_sessions_path,
             params: { title: "Auto Tool", curated_data: curated_data.to_json }.to_json,
             headers: auth_headers

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["tool_name"]).to eq("claude_code")
      end

      it "auto-generates title when not provided" do
        post api_agent_sessions_path,
             params: { curated_data: curated_data.to_json }.to_json,
             headers: auth_headers

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["title"]).to start_with("Session ")
      end

      it "returns 422 for invalid tool_name" do
        post api_agent_sessions_path,
             params: { title: "Bad Tool", tool_name: "invalid_tool",
                        curated_data: curated_data.to_json }.to_json,
             headers: auth_headers

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with s3_key only (CLI draft flow)" do
      it "creates a draft session with just s3_key" do
        post api_agent_sessions_path,
             params: { title: "CLI Draft", tool_name: "claude_code",
                        s3_key: "agent_sessions/#{user.id}/test.jsonl" }.to_json,
             headers: auth_headers

        expect(response).to have_http_status(:created)
        session = AgentSession.last
        expect(session.s3_key).to eq("agent_sessions/#{user.id}/test.jsonl")
        expect(session.curated_data).to eq({})
      end
    end

    it "returns 422 when no content is provided" do
      post api_agent_sessions_path,
           params: { title: "No content" }.to_json,
           headers: auth_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to include("Missing session content")
    end

    it "assigns the session to the authenticated user" do
      post api_agent_sessions_path,
           params: { title: "My Session", curated_data: curated_data.to_json }.to_json,
           headers: auth_headers

      expect(response).to have_http_status(:created)
      session = AgentSession.last
      expect(session.user_id).to eq(user.id)
    end
  end

  describe "POST /api/agent_sessions/presign" do
    context "when S3 is enabled" do
      before do
        allow(AgentSessions::S3Storage).to receive(:enabled?).and_return(true)
        allow(AgentSessions::S3Storage).to receive(:generate_key).and_return("agent_sessions/1/test.jsonl")
        allow(AgentSessions::S3Storage).to receive(:presigned_put_url).and_return("https://s3.example.com/presigned")
      end

      it "returns presigned URL and s3_key" do
        post presign_api_agent_sessions_path,
             params: {}.to_json,
             headers: auth_headers

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json["s3_key"]).to eq("agent_sessions/1/test.jsonl")
        expect(json["presigned_url"]).to eq("https://s3.example.com/presigned")
      end
    end

    context "when S3 is not enabled" do
      before do
        allow(AgentSessions::S3Storage).to receive(:enabled?).and_return(false)
      end

      it "returns 503" do
        post presign_api_agent_sessions_path,
             params: {}.to_json,
             headers: auth_headers
        expect(response).to have_http_status(:service_unavailable)
      end
    end

    it "returns 401 without authentication" do
      post presign_api_agent_sessions_path,
           params: {}.to_json,
           headers: headers
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/agent_sessions/:id/raw_url" do
    let!(:agent_session) do
      AgentSession.create!(
        user: user, title: "Test", tool_name: "claude_code",
        curated_data: curated_data,
        s3_key: "agent_sessions/#{user.id}/test.jsonl",
      )
    end

    context "when S3 is enabled" do
      before do
        allow(AgentSessions::S3Storage).to receive(:enabled?).and_return(true)
        allow(AgentSessions::S3Storage).to receive(:presigned_get_url).and_return("https://s3.example.com/get")
      end

      it "returns a presigned GET URL" do
        get raw_url_api_agent_session_path(agent_session), headers: auth_headers

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json["raw_url"]).to eq("https://s3.example.com/get")
      end
    end

    it "returns 404 when session has no s3_key" do
      session_without_s3 = AgentSession.create!(
        user: user, title: "No S3", tool_name: "claude_code",
        curated_data: curated_data,
      )
      get raw_url_api_agent_session_path(session_without_s3), headers: auth_headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/agent_sessions" do
    before do
      AgentSession.create!(user: user, title: "Session A", tool_name: "claude_code", curated_data: curated_data)
      AgentSession.create!(user: user, title: "Session B", tool_name: "codex", curated_data: curated_data)
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
      AgentSession.create!(user: other_user, title: "Other Session", tool_name: "pi", curated_data: curated_data)

      get api_agent_sessions_path, headers: auth_headers
      json = response.parsed_body
      expect(json.pluck("title")).not_to include("Other Session")
    end
  end

  describe "GET /api/agent_sessions/:id" do
    let!(:agent_session) do
      AgentSession.create!(user: user, title: "My Session", tool_name: "claude_code", curated_data: curated_data)
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
        user: other_user, title: "Other", tool_name: "codex", curated_data: curated_data,
      )
      get api_agent_session_path(other_session), headers: auth_headers
      expect(response).to have_http_status(:not_found)
    end
  end
end
