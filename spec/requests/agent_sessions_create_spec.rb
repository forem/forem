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

  describe "POST /agent_sessions (normalized_data mode)" do
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

  private

  def write_tmp_file(name, content)
    path = Rails.root.join("tmp", name)
    File.write(path, content)
    path
  end
end
