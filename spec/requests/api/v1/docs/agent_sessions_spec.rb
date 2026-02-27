require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName
# rubocop:disable Layout/LineLength

RSpec.describe "api/v1/agent_sessions" do
  let(:Accept) { "application/vnd.forem.api-v1+json" }
  let(:api_secret) { create(:api_secret) }
  let(:user) { api_secret.user }

  let(:normalized_data) do
    {
      "messages" => [
        { "index" => 0, "role" => "user", "content" => [{ "type" => "text", "text" => "Hello" }] },
        { "index" => 1, "role" => "assistant", "content" => [{ "type" => "text", "text" => "Hi there" }] },
      ],
      "metadata" => { "tool_name" => "claude_code", "total_messages" => 2 }
    }
  end

  let(:claude_code_jsonl) do
    [
      { type: "user", message: { role: "user", content: "Hello" }, uuid: "1",
        timestamp: "2025-01-01T00:00:00Z", sessionId: "s1" }.to_json,
      { type: "assistant", message: { role: "assistant", content: [{ type: "text", text: "Hi there" }] },
        uuid: "2", timestamp: "2025-01-01T00:00:01Z", sessionId: "s1" }.to_json,
    ].join("\n")
  end

  path "/api/agent_sessions" do
    describe "list agent sessions" do
      get("list the authenticated user's agent sessions") do
        tags "agent_sessions"
        description(<<~DESCRIBE.strip)
          This endpoint allows the client to list their own agent sessions.

          Agent sessions are coding conversation transcripts uploaded from CLI tools like
          [Claude Code](https://github.com/anthropics/claude-code). Use the
          [Forem CLI plugin](https://github.com/forem/forem-cli-plugin) to upload sessions
          from the command line.
        DESCRIBE
        operationId "getAgentSessions"
        produces "application/json"

        response(200, "successful") do
          let(:"api-key") { api_secret.secret }

          before do
            AgentSession.create!(user: user, title: "Session A", tool_name: "claude_code", normalized_data: normalized_data)
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
          This endpoint allows the client to upload a new agent session transcript.

          Accepts raw session content (JSONL from Claude Code, JSON from other tools) via
          the `body` parameter or as a `session_file` upload. The tool format is auto-detected
          unless `tool_name` is explicitly provided.

          Use the [Forem CLI plugin](https://github.com/forem/forem-cli-plugin) to upload
          sessions directly from the command line.
        DESCRIBE
        operationId "createAgentSession"
        produces "application/json"
        consumes "application/json"

        parameter name: :agent_session, in: :body, schema: {
          type: :object,
          properties: {
            title: { type: :string, description: "Title for the session (auto-generated if omitted)" },
            body: { type: :string, description: "Raw session content (JSONL or JSON). Provide this or session_file." },
            tool_name: { type: :string, description: "Tool that produced the session (e.g. claude_code, codex). Defaults to auto-detect.",
                         enum: %w[claude_code codex copilot_chat gemini_cli aider auto] }
          },
          required: %w[body]
        }

        let(:agent_session) do
          { title: "My Claude Session", body: claude_code_jsonl }
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
          This endpoint allows the client to retrieve a single agent session by slug or ID.
          Returns the full session including messages, curated selections, and slices.
        DESCRIBE
        operationId "getAgentSessionById"
        produces "application/json"

        parameter name: :id, in: :path, required: true,
                  description: "The slug or ID of the agent session.",
                  schema: { type: :string },
                  example: "my-session-abc123"

        let!(:agent_session) do
          AgentSession.create!(user: user, title: "My Session", tool_name: "claude_code", normalized_data: normalized_data)
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
end

# rubocop:enable Layout/LineLength
# rubocop:enable RSpec/VariableName
# rubocop:enable RSpec/EmptyExampleGroup
