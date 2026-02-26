require "rails_helper"

RSpec.describe AgentSessionParsers::ClaudeCode do
  describe ".parse" do
    it "parses a basic conversation" do
      jsonl = [
        {
          type: "user",
          message: { role: "user", content: "Fix the bug" },
          uuid: "u1", parentUuid: nil, timestamp: "2025-01-01T10:00:00Z",
          sessionId: "sess-1", cwd: "/home/user/project", gitBranch: "main",
        }.to_json,
        {
          type: "assistant",
          message: {
            role: "assistant",
            model: "claude-opus-4-6",
            content: [
              { type: "text", text: "I'll look into that." },
              { type: "tool_use", id: "tool1", name: "Read", input: { file_path: "/src/app.js" } },
            ],
          },
          uuid: "a1", parentUuid: "u1", timestamp: "2025-01-01T10:00:05Z",
          sessionId: "sess-1",
        }.to_json,
        {
          type: "user",
          message: {
            role: "user",
            content: [
              { type: "tool_result", tool_use_id: "tool1", content: "const app = express();" },
            ],
          },
          uuid: "u2", timestamp: "2025-01-01T10:00:06Z", sessionId: "sess-1",
        }.to_json,
        {
          type: "assistant",
          message: {
            role: "assistant",
            content: [{ type: "text", text: "Found the issue." }],
          },
          uuid: "a2", timestamp: "2025-01-01T10:00:10Z", sessionId: "sess-1",
        }.to_json,
      ].join("\n")

      result = described_class.parse(jsonl)

      expect(result["messages"].size).to eq(3)

      # First message: user text
      first = result["messages"][0]
      expect(first["role"]).to eq("user")
      expect(first["content"].first["text"]).to eq("Fix the bug")

      # Second message: assistant with tool call (result merged)
      second = result["messages"][1]
      expect(second["role"]).to eq("assistant")
      text_block = second["content"].find { |b| b["type"] == "text" }
      expect(text_block["text"]).to eq("I'll look into that.")
      tool_block = second["content"].find { |b| b["type"] == "tool_call" }
      expect(tool_block["name"]).to eq("Read")
      expect(tool_block["input"]).to eq("/src/app.js")
      expect(tool_block["output"]).to include("const app")

      # Third message: second assistant response
      third = result["messages"][2]
      expect(third["role"]).to eq("assistant")
      expect(third["content"].first["text"]).to eq("Found the issue.")

      # Metadata
      expect(result["metadata"]["tool_name"]).to eq("claude_code")
      expect(result["metadata"]["session_id"]).to eq("sess-1")
      expect(result["metadata"]["model"]).to eq("claude-opus-4-6")
    end

    it "skips progress and system records" do
      jsonl = [
        { type: "system", message: { role: "system", content: "You are helpful" } }.to_json,
        { type: "progress", content: "thinking..." }.to_json,
        { type: "user", message: { role: "user", content: "Hello" }, uuid: "u1", timestamp: "2025-01-01T10:00:00Z" }.to_json,
        { type: "file-history-snapshot", snapshot: {} }.to_json,
      ].join("\n")

      result = described_class.parse(jsonl)
      expect(result["messages"].size).to eq(1)
      expect(result["messages"].first["content"].first["text"]).to eq("Hello")
    end

    it "skips thinking blocks from assistant" do
      jsonl = [
        {
          type: "assistant",
          message: {
            role: "assistant",
            content: [
              { type: "thinking", thinking: "Let me consider..." },
              { type: "text", text: "Here's my answer." },
            ],
          },
          uuid: "a1", timestamp: "2025-01-01T10:00:00Z",
        }.to_json,
      ].join("\n")

      result = described_class.parse(jsonl)
      blocks = result["messages"].first["content"]
      expect(blocks.size).to eq(1)
      expect(blocks.first["type"]).to eq("text")
    end
  end
end
