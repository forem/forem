require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName
# rubocop:disable Layout/LineLength
# rubocop:disable RSpec/ScatteredSetup

RSpec.describe "api/v1/agent_sessions" do
  let(:Accept) { "application/vnd.forem.api-v1+json" }
  let(:api_secret) { create(:api_secret) }
  let(:user) { api_secret.user }

  let(:curated_data) do
    {
      "messages" => [
        { "index" => 0, "role" => "user", "content" => [{ "type" => "text", "text" => "Hello" }] },
        { "index" => 1, "role" => "assistant", "content" => [{ "type" => "text", "text" => "Hi there" }] },
      ],
      "metadata" => { "tool_name" => "claude_code", "total_messages" => 2 }
    }
  end

  path "/api/agent_sessions" do
    describe "list agent sessions" do
      get("list the authenticated user's agent sessions") do
        tags "agent_sessions"
        description(<<~DESCRIBE.strip)
          Retrieve a list of the authenticated user's agent sessions.

          ### Agent Sessions Overview:
          - Agent sessions represent coding conversation transcripts uploaded from CLI tools (like Claude Code).
          - Used by the developer portal to render interactive walkthroughs or session summaries.
          - Requires authentication.
        DESCRIBE
        operationId "getAgentSessions"
        produces "application/json"

        response(200, "successful") do
          let(:"api-key") { api_secret.secret }

          before do
            AgentSession.create!(user: user, title: "Session A", tool_name: "claude_code", curated_data: curated_data)
          end

          schema type: :array,
                 items: { "$ref": "#/components/schemas/AgentSessionIndex" }
          add_examples

          run_test!
        end

        response "401", "unauthorized" do
          let(:"api-key") { "invalid" }
          add_examples

          run_test!
        end
      end
    end

    describe "create an agent session" do
      post("upload a new agent session") do
        tags "agent_sessions"
        description(<<~DESCRIBE.strip)
          Upload a new agent session.

          ### S3 Upload Workflow:
          1. Call the S3 presign endpoint to obtain a direct upload URL for the raw session transcript file.
          2. Upload the raw transcript to S3.
          3. Send a POST request to this endpoint with the S3 key (`s3_key`) and the pre-parsed, curated JSON payload (`curated_data`).
        DESCRIBE
        operationId "createAgentSession"
        produces "application/json"
        consumes "application/json"

        parameter name: :agent_session, in: :body,
                  description: "Agent session upload parameters.",
                  schema: {
                    type: :object,
                    properties: {
                      title: { type: :string, description: "Title for the session (auto-generated if omitted)" },
                      curated_data: { type: :string, description: "JSON string of curated session data with messages array and metadata." },
                      s3_key: { type: :string, description: "S3 object key from presign endpoint (optional)." },
                      tool_name: { type: :string, description: "Tool that produced the session (e.g. claude_code, codex).",
                                   enum: AgentSession::TOOL_NAMES }
                    },
                    required: %w[curated_data]
                  }

        let(:agent_session) do
          { title: "My Claude Session", curated_data: curated_data.to_json }
        end

        response(201, "created") do
          let(:"api-key") { api_secret.secret }
          schema "$ref": "#/components/schemas/AgentSessionIndex"
          add_examples

          run_test!
        end

        response "401", "unauthorized" do
          let(:"api-key") { "invalid" }
          add_examples

          run_test!
        end

        response "422", "unprocessable" do
          let(:"api-key") { api_secret.secret }
          let(:agent_session) { { title: "No content" } }
          add_examples

          run_test!
        end
      end
    end
  end

  path "/api/agent_sessions/{id}" do
    describe "show an agent session" do
      get("show details for an agent session") do
        tags "agent_sessions"
        description(<<~DESCRIBE.strip)
          Retrieve details for a single agent session by unique slug or ID.

          ### Integration Tip:
          - Returns the complete session structure including parsed message logs, token counts, slices, and tool execution metadata.
        DESCRIBE
        operationId "getAgentSessionById"
        produces "application/json"

        parameter name: :id, in: :path, required: true,
                  description: "The unique slug or ID of the agent session.",
                  schema: { type: :string },
                  example: "my-session-abc123"

        let!(:agent_session) do
          AgentSession.create!(user: user, title: "My Session", tool_name: "claude_code", curated_data: curated_data)
        end
        let(:id) { agent_session.slug }

        response(200, "successful") do
          let(:"api-key") { api_secret.secret }
          schema "$ref": "#/components/schemas/AgentSessionShow"
          add_examples

          run_test!
        end

        response "401", "unauthorized" do
          let(:"api-key") { "invalid" }
          add_examples

          run_test!
        end

        response "404", "not found" do
          let(:"api-key") { api_secret.secret }
          let(:id) { "nonexistent-slug" }
          add_examples

          run_test!
        end
      end
    end
  end
  path "/api/agent_sessions/presign" do
    describe "presign an agent session upload" do
      post("request a presigned S3 upload URL") do
        tags "agent_sessions"
        description(<<~DESCRIBE.strip)
          Generate a presigned S3 PUT URL to directly upload a raw agent session transcript file before creating the session record.

          ### S3 Upload Workflow:
          1. Call this endpoint to receive a `presigned_url` and `s3_key`.
          2. Send an HTTP PUT request with the raw session payload directly to the `presigned_url`.
          3. Complete the creation by calling `POST /api/agent_sessions` with the `s3_key` and curated transcript data.
        DESCRIBE
        operationId "presignAgentSessionUpload"
        produces "application/json"
        consumes "application/json"

        response(200, "successful") do
          let(:"api-key") { api_secret.secret }

          before do
            allow(AgentSessions::S3Storage).to receive_messages(
              enabled?: true,
              generate_key: "agent_sessions/#{user.id}/test.jsonl",
              presigned_put_url: "https://s3.example.com/presigned",
            )
          end

          schema type: :object,
                 properties: {
                   s3_key: { type: :string, description: "S3 object key under which the session file should be uploaded" },
                   presigned_url: { type: :string, format: :url, description: "Direct S3 presigned PUT URL" }
                 },
                 required: %w[s3_key presigned_url]
          add_examples

          run_test!
        end

        response "401", "unauthorized" do
          let(:"api-key") { "invalid" }
          add_examples

          run_test!
        end

        response "503", "service unavailable" do
          let(:"api-key") { api_secret.secret }

          before do
            allow(AgentSessions::S3Storage).to receive(:enabled?).and_return(false)
          end

          add_examples

          run_test!
        end
      end
    end
  end

  path "/api/agent_sessions/{id}/raw_url" do
    describe "get raw transcript download URL" do
      get("retrieve presigned raw transcript download URL") do
        tags "agent_sessions"
        description(<<~DESCRIBE.strip)
          Retrieve a presigned S3 GET URL to download the original raw transcript file for an agent session.

          ### Notes:
          - Requires authentication and ownership of the session.
          - Returns 404 if no raw file was uploaded for the session.
        DESCRIBE
        operationId "getAgentSessionRawUrl"
        produces "application/json"

        parameter name: :id, in: :path, required: true,
                  description: "The unique slug or ID of the agent session.",
                  schema: { type: :string },
                  example: "my-session-abc123"

        let!(:agent_session) do
          AgentSession.create!(
            user: user,
            title: "My Session with Raw Transcript",
            tool_name: "claude_code",
            curated_data: curated_data,
            s3_key: "agent_sessions/#{user.id}/test.jsonl",
          )
        end
        let(:id) { agent_session.slug }

        response(200, "successful") do
          let(:"api-key") { api_secret.secret }

          before do
            allow(AgentSessions::S3Storage).to receive_messages(
              enabled?: true,
              presigned_get_url: "https://s3.example.com/get",
            )
          end

          schema type: :object,
                 properties: {
                   raw_url: { type: :string, format: :url, description: "Presigned S3 GET URL for downloading the raw transcript" }
                 },
                 required: %w[raw_url]
          add_examples

          run_test!
        end

        response "401", "unauthorized" do
          let(:"api-key") { "invalid" }
          add_examples

          run_test!
        end

        response "404", "not found" do
          let(:"api-key") { api_secret.secret }
          let(:id) { "nonexistent-session" }
          add_examples

          run_test!
        end
      end
    end
  end
end

# rubocop:enable Layout/LineLength
# rubocop:enable RSpec/VariableName
# rubocop:enable RSpec/EmptyExampleGroup
# rubocop:enable RSpec/ScatteredSetup
