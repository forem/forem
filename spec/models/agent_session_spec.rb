require "rails_helper"

RSpec.describe AgentSession, type: :model do
  let(:user) { create(:user) }
  let(:normalized_data) do
    {
      "messages" => [
        { "index" => 0, "role" => "user", "content" => [{ "type" => "text", "text" => "Hello" }] },
        { "index" => 1, "role" => "assistant", "content" => [{ "type" => "text", "text" => "Hi there" }] },
        { "index" => 2, "role" => "user", "content" => [{ "type" => "text", "text" => "Fix the bug" }] },
        { "index" => 3, "role" => "assistant", "content" => [
          { "type" => "text", "text" => "Let me check" },
          { "type" => "tool_call", "name" => "Read", "input" => "/src/app.js", "output" => "code here" },
        ] },
      ],
      "metadata" => { "tool_name" => "claude_code", "total_messages" => 4 },
    }
  end

  let(:agent_session) do
    described_class.create!(
      user: user,
      title: "Test Session",
      tool_name: "claude_code",
      normalized_data: normalized_data,
    )
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:tool_name) }
    it { is_expected.to validate_length_of(:title).is_at_most(200) }

    it "validates tool_name inclusion" do
      session = described_class.new(user: user, title: "Test", tool_name: "invalid_tool")
      expect(session).not_to be_valid
      expect(session.errors[:tool_name]).to be_present
    end

    it "accepts all valid tool names" do
      AgentSession::TOOL_NAMES.each do |tool|
        session = described_class.new(user: user, title: "Test", tool_name: tool, normalized_data: normalized_data)
        expect(session).to be_valid, "Expected #{tool} to be valid"
      end
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "#messages" do
    it "returns messages from normalized_data" do
      expect(agent_session.messages.size).to eq(4)
      expect(agent_session.messages.first["role"]).to eq("user")
    end

    it "returns empty array when normalized_data has no messages" do
      session = described_class.new(normalized_data: {})
      expect(session.messages).to eq([])
    end
  end

  describe "#curated_messages" do
    it "returns all messages when no curated_selections" do
      expect(agent_session.curated_messages).to eq(agent_session.messages)
    end

    it "returns only selected messages" do
      agent_session.update!(curated_selections: [0, 3])
      curated = agent_session.curated_messages
      expect(curated.size).to eq(2)
      expect(curated.map { |m| m["index"] }).to eq([0, 3])
    end
  end

  describe "#total_messages" do
    it "returns the count of messages" do
      expect(agent_session.total_messages).to eq(4)
    end
  end

  describe "#curated_count" do
    it "returns total_messages when no curated_selections" do
      expect(agent_session.curated_count).to eq(4)
    end

    it "returns size of curated_selections" do
      agent_session.update!(curated_selections: [0, 1])
      expect(agent_session.curated_count).to eq(2)
    end
  end

  describe "#parse_and_normalize!" do
    it "parses Claude Code JSONL content" do
      jsonl_content = [
        { type: "user", message: { role: "user", content: "Hello" }, uuid: "1", timestamp: "2025-01-01T00:00:00Z", sessionId: "s1" }.to_json,
        { type: "assistant", message: { role: "assistant", content: [{ type: "text", text: "Hi" }] }, uuid: "2", timestamp: "2025-01-01T00:00:01Z", sessionId: "s1" }.to_json,
      ].join("\n")

      session = described_class.new(user: user, title: "Test")
      session.parse_and_normalize!(jsonl_content, detected_tool: "claude_code")

      expect(session.tool_name).to eq("claude_code")
      expect(session.messages.size).to eq(2)
      expect(session.messages.first["role"]).to eq("user")
    end
  end

  describe "#curated_messages_in_range" do
    before { agent_session.update!(curated_selections: [0, 1, 2, 3]) }

    it "returns curated messages within the given range" do
      result = agent_session.curated_messages_in_range(0..1)
      expect(result.map { |m| m["index"] }).to eq([0, 1])
    end

    it "returns empty when range has no curated messages" do
      agent_session.update!(curated_selections: [3])
      result = agent_session.curated_messages_in_range(0..1)
      expect(result).to be_empty
    end
  end

  describe "#find_slice" do
    before do
      agent_session.update!(slices: [
        { "name" => "planning", "indices" => [0, 1] },
        { "name" => "implementation", "indices" => [2, 3] },
      ])
    end

    it "finds a slice by name (case insensitive)" do
      expect(agent_session.find_slice("Planning")).to eq({ "name" => "planning", "indices" => [0, 1] })
    end

    it "returns nil for unknown slice" do
      expect(agent_session.find_slice("nonexistent")).to be_nil
    end
  end

  describe "#messages_for_slice" do
    before do
      agent_session.update!(slices: [
        { "name" => "planning", "indices" => [0, 1] },
      ])
    end

    it "returns messages for the named slice" do
      result = agent_session.messages_for_slice("planning")
      expect(result.size).to eq(2)
      expect(result.map { |m| m["index"] }).to eq([0, 1])
    end

    it "returns empty for unknown slice" do
      expect(agent_session.messages_for_slice("nonexistent")).to eq([])
    end
  end

  describe "#slug" do
    it "auto-generates a slug from the title on create" do
      session = described_class.create!(user: user, title: "My Cool Session", tool_name: "claude_code", normalized_data: normalized_data)
      expect(session.slug).to match(/\Amy-cool-session-[a-z0-9]+\z/)
    end

    it "does not overwrite an existing slug on update" do
      original_slug = agent_session.slug
      agent_session.update!(title: "Changed Title")
      expect(agent_session.reload.slug).to eq(original_slug)
    end

    it "enforces uniqueness scoped to user" do
      agent_session # create first
      duplicate = described_class.new(user: user, title: "Other", tool_name: "codex", normalized_data: normalized_data, slug: agent_session.slug)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:slug]).to be_present
    end
  end

  describe "#to_param" do
    it "returns the slug" do
      expect(agent_session.to_param).to eq(agent_session.slug)
    end
  end

  describe "scope" do
    it ".published returns only published sessions" do
      agent_session.update!(published: true)
      unpublished = described_class.create!(user: user, title: "Unpub", tool_name: "codex", normalized_data: normalized_data)

      expect(described_class.published).to include(agent_session)
      expect(described_class.published).not_to include(unpublished)
    end
  end
end
