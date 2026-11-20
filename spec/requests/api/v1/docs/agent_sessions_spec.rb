require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName
# rubocop:disable Layout/LineLength

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
          2. Upload the raw transcript to S3 with a PUT to `presigned_url`, sending exactly the returned `headers`.
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
    describe "obtain a presigned S3 upload URL" do
      post("request a presigned URL to upload raw session transcript to S3") do
        tags "agent_sessions"
        description(<<~DESCRIBE.strip)
          Generate an S3 presigned PUT URL and object key for uploading raw session transcripts directly to S3.

          ### Upload Rules:
          - Declare the exact size of the file in bytes as `content_length`. The maximum is #{AgentSessions::S3Storage::MAX_UPLOAD_SIZE} bytes (#{AgentSessions::S3Storage::MAX_UPLOAD_SIZE / 1.megabyte}MB), the same limit applied to curated session data.
          - PUT the file to `presigned_url` within 15 minutes, sending exactly the returned `headers`. The size is part of the signature, so S3 rejects a body of any other length.
          - Rate limited per user to a configurable number of URLs per configurable window (by default 20 per hour), counted whether or not a session is later created. Exceeding it returns `429` with a `Retry-After` header. Forem admins can change both values, or set the limit to 0 to disable uploads.
        DESCRIBE
        operationId "presignAgentSession"
        produces "application/json"
        consumes "application/json"

        parameter name: :presign_params, in: :body,
                  description: "Size of the file to upload.",
                  schema: {
                    type: :object,
                    properties: {
                      content_length: { type: :integer, minimum: 1, maximum: AgentSessions::S3Storage::MAX_UPLOAD_SIZE,
                                        description: "Exact size of the raw transcript in bytes." }
                    },
                    required: %w[content_length]
                  }

        let(:presign_params) { { content_length: 1024 } }
        let(:s3_enabled) { true }
        let(:presign_limit) { 20 }

        before do
          allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
          allow(Settings::RateLimit).to receive(:agent_session_presign).and_return(presign_limit)
          allow(AgentSessions::S3Storage).to receive_messages(
            enabled?: s3_enabled,
            generate_key: "agent_sessions/#{user.id}/#{SecureRandom.uuid}.jsonl",
            presigned_put_url: "https://s3.example.com/presigned",
          )
        end

        response(200, "successful") do
          let(:"api-key") { api_secret.secret }

          schema type: :object,
                 properties: {
                   s3_key: { type: :string },
                   presigned_url: { type: :string },
                   headers: {
                     type: :object,
                     description: "Headers to send with the PUT to presigned_url. Each is part of the signature.",
                     properties: {
                       "Content-Type": { type: :string },
                       "Content-Length": { type: :string },
                       "x-amz-acl": { type: :string }
                     },
                     required: %w[Content-Type Content-Length x-amz-acl]
                   }
                 },
                 required: %w[s3_key presigned_url headers]
          add_examples

          run_test!
        end

        response "401", "unauthorized" do
          let(:"api-key") { "invalid" }
          add_examples

          run_test!
        end

        response "422", "missing or too large content_length" do
          let(:"api-key") { api_secret.secret }
          let(:presign_params) { { content_length: AgentSessions::S3Storage::MAX_UPLOAD_SIZE + 1 } }
          add_examples

          run_test!
        end

        response "429", "too many requests" do
          let(:"api-key") { api_secret.secret }
          let(:presign_limit) { 0 }
          add_examples

          run_test!
        end

        response "503", "service unavailable" do
          let(:"api-key") { api_secret.secret }
          let(:s3_enabled) { false }
          add_examples

          run_test!
        end
      end
    end
  end

  path "/api/agent_sessions/{id}/raw_url" do
    describe "obtain presigned raw download URL" do
      get("request a presigned S3 GET URL to download the raw session transcript") do
        tags "agent_sessions"
        description(<<~DESCRIBE.strip)
          Retrieve a temporary presigned GET URL to download the original raw transcript file from S3.
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
            title: "My Session",
            tool_name: "claude_code",
            curated_data: curated_data,
            s3_key: "agent_sessions/#{user.id}/#{SecureRandom.uuid}.jsonl",
          )
        end
        let(:id) { agent_session.slug }

        response(200, "successful") do
          let(:"api-key") { api_secret.secret }

          before do
            allow(AgentSessions::S3Storage).to receive_messages(enabled?: true, presigned_get_url: "https://s3.example.com/get")
          end

          schema type: :object,
                 properties: {
                   raw_url: { type: :string }
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
          let(:id) { "nonexistent-slug" }
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
