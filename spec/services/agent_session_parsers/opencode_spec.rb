require "rails_helper"

RSpec.describe AgentSessionParsers::Opencode do
  describe ".parse" do
    it "parses OpenCode export messages and parts" do # rubocop:disable RSpec/MultipleExpectations
      export = {
        "info" => {
          "id" => "session_xyz",
          "slug" => "abc123",
          "directory" => "/home/user/project",
          "version" => "1.2.3",
          "summary" => { "files" => 2 },
          "share" => { "url" => "https://opncd.ai/share/xyz" },
          "time" => { "created" => 1_741_176_000_000, "updated" => 1_741_176_100_000 }
        },
        "messages" => [
          {
            "info" => {
              "id" => "msg_1",
              "role" => "user",
              "time" => { "created" => 1_741_176_001_000 },
              "model" => { "providerID" => "openai", "modelID" => "gpt-4o" }
            },
            "parts" => [
              { "type" => "text", "text" => "Add a login button" },
            ]
          },
          {
            "info" => {
              "id" => "msg_2",
              "role" => "assistant",
              "time" => { "created" => 1_741_176_002_000 },
              "model" => { "providerID" => "openai", "modelID" => "gpt-4o" },
              "error" => { "name" => "APIError", "message" => "rate limited", "statusCode" => 429 }
            },
            "parts" => [
              { "type" => "reasoning", "text" => "Need to inspect the navbar first" },
              {
                "type" => "tool",
                "tool" => "edit",
                "state" => {
                  "status" => "completed",
                  "title" => "Editing app/views/layout.html.erb",
                  "input" => { "path" => "app/views/layout.html.erb" },
                  "output" => "Done"
                }
              },
              { "type" => "step-finish", "reason" => "completed" },
            ]
          },
        ]
      }

      result = described_class.parse(export.to_json)

      expect(result["messages"].size).to eq(2)
      expect(result["messages"].first["role"]).to eq("user")
      expect(result["messages"].first["content"].first["text"]).to eq("Add a login button")

      assistant = result["messages"].second
      expect(assistant["model"]).to eq("openai/gpt-4o")
      expect(assistant["timestamp"]).to eq("2025-03-05T12:00:02Z")

      reasoning = assistant["content"].detect { |b| b["type"] == "text" && b["text"].start_with?("**Reasoning:**") }
      expect(reasoning).to be_present

      tool = assistant["content"].detect { |b| b["type"] == "tool_call" }
      expect(tool["name"]).to eq("edit")
      expect(tool["input"]).to include("path")
      expect(tool["output"]).to include("status=completed")

      expect(result["metadata"]["tool_name"]).to eq("opencode")
      expect(result["metadata"]["session_id"]).to eq("session_xyz")
      expect(result["metadata"]["todo_note"]).to include("omits todos")
      expect(result["metadata"]["share_url"]).to eq("https://opncd.ai/share/xyz")
    end

    it "raises for non-OpenCode JSON" do
      expect { described_class.parse({ hello: "world" }.to_json) }
        .to raise_error(ArgumentError, /Invalid OpenCode export format/)
    end
  end
end
