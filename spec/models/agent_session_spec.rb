require "rails_helper"

RSpec.describe AgentSession do
  let(:user) { create(:user) }
  let(:curated_data) do
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
      "metadata" => { "tool_name" => "claude_code", "total_messages" => 4 }
    }
  end

  let(:agent_session) do
    described_class.create!(
      user: user,
      title: "Test Session",
      tool_name: "claude_code",
      curated_data: curated_data,
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
        session = described_class.new(user: user, title: "Test", tool_name: tool, curated_data: curated_data)
        expect(session).to be_valid, "Expected #{tool} to be valid"
      end
    end

    it "validates curated_data has messages when present" do
      session = described_class.new(user: user, title: "Test", tool_name: "claude_code",
                                    curated_data: { "not_messages" => [] })
      expect(session).not_to be_valid
      expect(session.errors[:curated_data]).to be_present
    end

    it "allows saving with just s3_key and no data (draft state)" do
      session = described_class.new(user: user, title: "Draft", tool_name: "claude_code",
                                    s3_key: "agent_sessions/1/test.jsonl")
      expect(session).to be_valid
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "#messages" do
    it "returns messages from curated_data" do
      expect(agent_session.messages.size).to eq(4)
      expect(agent_session.messages.first["role"]).to eq("user")
    end

    it "returns empty array when curated_data has no messages" do
      session = described_class.new(curated_data: {})
      expect(session.messages).to eq([])
    end
  end

  describe "#curated_messages" do
    it "returns all messages" do
      expect(agent_session.curated_messages).to eq(agent_session.messages)
    end
  end

  describe "#metadata" do
    it "returns metadata from curated_data" do
      expect(agent_session.metadata["tool_name"]).to eq("claude_code")
    end
  end

  describe "#total_messages" do
    it "returns the count of messages" do
      expect(agent_session.total_messages).to eq(4)
    end
  end

  describe "#curated_count" do
    it "returns the message count" do
      expect(agent_session.curated_count).to eq(4)
    end
  end

  describe "#s3_session?" do
    it "returns false when no s3_key" do
      expect(agent_session.s3_session?).to be false
    end

    it "returns true when s3_key is present" do
      agent_session.update!(s3_key: "agent_sessions/1/test.jsonl")
      expect(agent_session.s3_session?).to be true
    end
  end

  describe "#raw_file_available?" do
    it "returns false when no s3_key" do
      expect(agent_session.raw_file_available?).to be false
    end

    it "returns true when s3_key is present and within retention window" do
      agent_session.update!(s3_key: "agent_sessions/1/test.jsonl")
      expect(agent_session.raw_file_available?).to be true
    end

    it "returns false when s3_key is present but beyond retention window" do
      agent_session.update!(s3_key: "agent_sessions/1/test.jsonl", created_at: 91.days.ago)
      expect(agent_session.raw_file_available?).to be false
    end
  end

  describe "S3 cleanup on destroy" do
    it "deletes S3 object when session is destroyed" do
      agent_session.update!(s3_key: "agent_sessions/1/test.jsonl")
      allow(AgentSessions::S3Storage).to receive(:enabled?).and_return(true)
      expect(AgentSessions::S3Storage).to receive(:delete).with("agent_sessions/1/test.jsonl")

      agent_session.destroy
    end

    it "does not attempt S3 delete when no s3_key" do
      expect(AgentSessions::S3Storage).not_to receive(:delete)
      agent_session.destroy
    end

    it "does not attempt S3 delete when S3 is not enabled" do
      agent_session.update!(s3_key: "agent_sessions/1/test.jsonl")
      allow(AgentSessions::S3Storage).to receive(:enabled?).and_return(false)
      expect(AgentSessions::S3Storage).not_to receive(:delete)

      agent_session.destroy
    end
  end

  describe "#curated_messages_in_range" do
    it "returns messages within the given range" do
      result = agent_session.curated_messages_in_range(0..1)
      expect(result.pluck("index")).to eq([0, 1])
    end

    it "returns empty when range has no messages" do
      small_session = described_class.create!(
        user: user, title: "Small", tool_name: "claude_code",
        curated_data: {
          "messages" => [{ "index" => 3, "role" => "assistant", "content" => [{ "type" => "text", "text" => "x" }] }],
          "metadata" => {}
        },
      )
      result = small_session.curated_messages_in_range(0..1)
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
      expect(result.pluck("index")).to eq([0, 1])
    end

    it "returns empty for unknown slice" do
      expect(agent_session.messages_for_slice("nonexistent")).to eq([])
    end
  end

  describe "#slug" do
    it "auto-generates a slug from the title on create" do
      session = described_class.create!(user: user, title: "My Cool Session", tool_name: "claude_code",
                                        curated_data: curated_data)
      expect(session.slug).to match(/\Amy-cool-session-[a-z0-9]+\z/)
    end

    it "does not overwrite an existing slug on update" do
      original_slug = agent_session.slug
      agent_session.update!(title: "Changed Title")
      expect(agent_session.reload.slug).to eq(original_slug)
    end

    it "enforces uniqueness" do
      agent_session # create first
      duplicate = described_class.new(user: user, title: "Other", tool_name: "codex", curated_data: curated_data,
                                      slug: agent_session.slug)
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
      unpublished = described_class.create!(user: user, title: "Unpub", tool_name: "codex",
                                            curated_data: curated_data)

      expect(described_class.published).to include(agent_session)
      expect(described_class.published).not_to include(unpublished)
    end
  end
end
