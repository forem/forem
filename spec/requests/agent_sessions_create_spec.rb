require "rails_helper"

RSpec.describe "AgentSessions#create" do
  let(:user) { create(:user) }

  before { sign_in user }

  def valid_normalized_data
    {
      "messages" => [
        { "index" => 0, "role" => "user", "content" => [{ "type" => "text", "text" => "Hello" }] },
        { "index" => 1, "role" => "assistant", "content" => [{ "type" => "text", "text" => "Hi" }] },
      ],
      "metadata" => { "tool_name" => "claude_code", "total_messages" => 2 }
    }
  end

  def valid_curated_data
    valid_normalized_data
  end

  describe "POST /agent_sessions (curated_data mode)" do
    it "creates a session from curated_data with s3_key" do
      post agent_sessions_path, params: {
        agent_session: {
          title: "My S3 Session",
          tool_name: "claude_code",
          curated_data: valid_curated_data.to_json,
          s3_key: "agent_sessions/#{user.id}/test.jsonl",
        }
      }, as: :json

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["success"]).to be true

      session = AgentSession.last
      expect(session.title).to eq("My S3 Session")
      expect(session.curated_data["messages"].size).to eq(2)
      expect(session.s3_key).to eq("agent_sessions/#{user.id}/test.jsonl")
      expect(session.normalized_data).to eq({})
    end

    it "creates a session from curated_data without s3_key" do
      post agent_sessions_path, params: {
        agent_session: {
          title: "No S3 Session",
          tool_name: "claude_code",
          curated_data: valid_curated_data.to_json,
        }
      }, as: :json

      expect(response).to have_http_status(:ok)
      session = AgentSession.last
      expect(session.curated_data["messages"].size).to eq(2)
      expect(session.s3_key).to be_nil
    end

    it "runs server-side secret scrubbing on curated_data" do
      data_with_secret = valid_curated_data.deep_dup
      data_with_secret["messages"][0]["content"][0]["text"] = "My key is ghp_abcdefghijklmnopqrstuvwxyz1234567890"

      post agent_sessions_path, params: {
        agent_session: {
          title: "Scrubbed Session",
          tool_name: "claude_code",
          curated_data: data_with_secret.to_json,
        }
      }, as: :json

      expect(response).to have_http_status(:ok)
      session = AgentSession.last
      text = session.curated_data["messages"].first["content"].first["text"]
      expect(text).to include("[REDACTED]")
      expect(text).not_to include("ghp_")
    end

    it "rejects invalid curated_data structure" do
      post agent_sessions_path, params: {
        agent_session: {
          title: "Bad Data",
          tool_name: "claude_code",
          curated_data: { "not_messages" => [] }.to_json,
        }
      }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      json = response.parsed_body
      expect(json["error"]).to include("Missing required key: messages")
    end
  end

  describe "POST /agent_sessions (normalized_data mode — legacy)" do
    it "creates a session from client-parsed normalized_data JSON" do
      post agent_sessions_path, params: {
        agent_session: {
          title: "My Curated Session",
          tool_name: "claude_code",
          normalized_data: valid_normalized_data.to_json,
        }
      }, as: :json

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["success"]).to be true
      expect(json["redirect_to"]).to be_present

      session = AgentSession.last
      expect(session.title).to eq("My Curated Session")
      expect(session.tool_name).to eq("claude_code")
      expect(session.messages.size).to eq(2)
      expect(session.raw_data).to be_nil
    end

    it "infers tool_name from metadata when not provided" do
      post agent_sessions_path, params: {
        agent_session: {
          title: "Inferred Tool",
          normalized_data: valid_normalized_data.to_json,
        }
      }, as: :json

      expect(response).to have_http_status(:ok)
      session = AgentSession.last
      expect(session.tool_name).to eq("claude_code")
    end

    it "runs server-side secret scrubbing on client-parsed data" do
      data_with_secret = valid_normalized_data.deep_dup
      data_with_secret["messages"][0]["content"][0]["text"] = "My key is ghp_abcdefghijklmnopqrstuvwxyz1234567890"

      post agent_sessions_path, params: {
        agent_session: {
          title: "Scrubbed Session",
          tool_name: "claude_code",
          normalized_data: data_with_secret.to_json,
        }
      }, as: :json

      expect(response).to have_http_status(:ok)
      session = AgentSession.last
      text = session.messages.first["content"].first["text"]
      expect(text).to include("[REDACTED]")
      expect(text).not_to include("ghp_")
    end

    it "saves slices when provided" do
      post agent_sessions_path, params: {
        agent_session: {
          title: "Session with Slices",
          tool_name: "claude_code",
          normalized_data: valid_normalized_data.to_json,
          slices: [{ name: "intro", indices: [0] }].to_json,
        }
      }, as: :json

      expect(response).to have_http_status(:ok)
      session = AgentSession.last
      expect(session.slices.size).to eq(1)
      expect(session.slices.first["name"]).to eq("intro")
    end

    it "rejects invalid normalized_data structure" do
      post agent_sessions_path, params: {
        agent_session: {
          title: "Bad Data",
          tool_name: "claude_code",
          normalized_data: { "not_messages" => [] }.to_json,
        }
      }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      json = response.parsed_body
      expect(json["error"]).to include("Missing required key: messages")
    end

    it "rejects messages with invalid roles" do
      bad_data = { "messages" => [{ "role" => "system", "content" => [{ "type" => "text", "text" => "x" }] }] }

      post agent_sessions_path, params: {
        agent_session: {
          title: "Bad Roles",
          tool_name: "claude_code",
          normalized_data: bad_data.to_json,
        }
      }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      json = response.parsed_body
      expect(json["error"]).to include("invalid role")
    end
  end

  describe "POST /agent_sessions (file upload mode)" do
    it "still works with traditional file upload" do
      file_content = [
        { "type" => "user", "message" => { "role" => "user", "content" => "Hello" }, "timestamp" => "2024-01-01T00:00:00Z", "sessionId" => "s1" }.to_json,
        { "type" => "assistant", "message" => { "role" => "assistant", "content" => [{ "type" => "text", "text" => "Hi" }] }, "timestamp" => "2024-01-01T00:00:01Z", "sessionId" => "s1" }.to_json,
      ].join("\n")

      file = fixture_file_upload(
        write_tmp_file("session.jsonl", file_content),
        "application/octet-stream",
      )

      post agent_sessions_path, params: {
        agent_session: {
          title: "File Upload Test",
          tool_name: "claude_code",
          session_file: file,
        }
      }, headers: { "Accept" => "application/json" }

      expect(response).to have_http_status(:ok)
      session = AgentSession.last
      expect(session.title).to eq("File Upload Test")
      expect(session.messages).to be_present
    end
  end

  describe "POST /agent_sessions/presign" do
    context "when S3 is enabled" do
      before do
        allow(AgentSessions::S3Storage).to receive(:enabled?).and_return(true)
        allow(AgentSessions::S3Storage).to receive(:generate_key).and_return("agent_sessions/1/test.jsonl")
        allow(AgentSessions::S3Storage).to receive(:presigned_put_url).and_return("https://s3.example.com/presigned")
      end

      it "returns presigned URL and s3_key" do
        post presign_agent_sessions_path, as: :json

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
        post presign_agent_sessions_path, as: :json
        expect(response).to have_http_status(:service_unavailable)
      end
    end

    it "requires authentication" do
      sign_out user
      post presign_agent_sessions_path, as: :json
      # May redirect to login or return 401 depending on format
      expect(response.status).to be_in([302, 401])
    end
  end

  describe "GET /agent_sessions/:id/raw_url" do
    let(:agent_session) do
      AgentSession.create!(
        user: user, title: "Test", tool_name: "claude_code",
        normalized_data: valid_normalized_data,
        s3_key: "agent_sessions/#{user.id}/test.jsonl",
      )
    end

    context "when S3 is enabled" do
      before do
        allow(AgentSessions::S3Storage).to receive(:enabled?).and_return(true)
        allow(AgentSessions::S3Storage).to receive(:presigned_get_url).and_return("https://s3.example.com/get")
      end

      it "returns a presigned GET URL" do
        get raw_url_agent_session_path(agent_session), as: :json

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json["raw_url"]).to eq("https://s3.example.com/get")
      end
    end

    it "returns 404 when session has no s3_key" do
      session_without_s3 = AgentSession.create!(
        user: user, title: "No S3", tool_name: "claude_code",
        normalized_data: valid_normalized_data,
      )

      get raw_url_agent_session_path(session_without_s3), as: :json
      expect(response).to have_http_status(:not_found)
    end

    it "requires the session owner" do
      other_user = create(:user)
      sign_in other_user

      expect {
        get raw_url_agent_session_path(agent_session), as: :json
      }.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  describe "PATCH /agent_sessions/:id (curated_data update)" do
    let(:agent_session) do
      AgentSession.create!(
        user: user, title: "Test", tool_name: "claude_code",
        curated_data: valid_curated_data,
        s3_key: "agent_sessions/#{user.id}/test.jsonl",
      )
    end

    it "updates curated_data" do
      new_curated = {
        "messages" => [
          { "index" => 0, "role" => "user", "content" => [{ "type" => "text", "text" => "Only this" }] },
        ],
        "metadata" => {}
      }

      patch agent_session_path(agent_session), params: {
        agent_session: { curated_data: new_curated.to_json }
      }, as: :json

      expect(response).to have_http_status(:ok)
      agent_session.reload
      expect(agent_session.curated_data["messages"].size).to eq(1)
    end
  end

  private

  def write_tmp_file(name, content)
    path = Rails.root.join("tmp", name)
    File.write(path, content)
    path
  end
end
