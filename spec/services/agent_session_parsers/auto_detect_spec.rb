require "rails_helper"

RSpec.describe AgentSessionParsers::AutoDetect do
  describe ".detect_tool" do
    it "detects Claude Code from JSONL with sessionId" do
      content = { type: "user", sessionId: "sess-1", message: { role: "user", content: "Hi" } }.to_json
      expect(described_class.detect_tool(content)).to eq("claude_code")
    end

    it "detects Codex from event types" do
      content = { type: "thread.started", thread_id: "t1" }.to_json
      expect(described_class.detect_tool(content)).to eq("codex")
    end

    it "detects Gemini CLI from session_metadata" do
      content = { type: "session_metadata", session_id: "s1" }.to_json
      expect(described_class.detect_tool(content)).to eq("gemini_cli")
    end

    it "detects Pi from parentId field" do
      content = { id: "1", parentId: nil, type: "user", message: { role: "user" } }.to_json
      expect(described_class.detect_tool(content)).to eq("pi")
    end

    it "detects Pi from session type with version" do
      content = { type: "session", version: 3, id: "abc" }.to_json
      expect(described_class.detect_tool(content)).to eq("pi")
    end
  end

  describe ".parser_for" do
    it "returns correct parser for each tool" do
      expect(described_class.parser_for("claude_code")).to eq(AgentSessionParsers::ClaudeCode)
      expect(described_class.parser_for("codex")).to eq(AgentSessionParsers::Codex)
      expect(described_class.parser_for("gemini_cli")).to eq(AgentSessionParsers::GeminiCli)
      expect(described_class.parser_for("pi")).to eq(AgentSessionParsers::Pi)
    end

    it "raises for unknown tools" do
      expect { described_class.parser_for("unknown") }.to raise_error(ArgumentError, /Unknown agent tool/)
    end
  end

  describe ".detect_and_parse" do
    it "detects and parses Claude Code content" do
      content = [
        { type: "user", sessionId: "s1", message: { role: "user", content: "Hello" }, uuid: "1", timestamp: "2025-01-01T00:00:00Z" }.to_json,
        { type: "assistant", sessionId: "s1", message: { role: "assistant", content: [{ type: "text", text: "Hi" }] }, uuid: "2", timestamp: "2025-01-01T00:00:01Z" }.to_json,
      ].join("\n")

      tool, result = described_class.detect_and_parse(content)
      expect(tool).to eq("claude_code")
      expect(result["messages"].size).to eq(2)
    end
  end
end
