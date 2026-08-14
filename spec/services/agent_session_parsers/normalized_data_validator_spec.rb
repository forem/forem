require "rails_helper"

RSpec.describe AgentSessionParsers::NormalizedDataValidator do
  def valid_data(overrides = {})
    {
      "messages" => [
        { "role" => "user", "content" => [{ "type" => "text", "text" => "Hello" }] },
        { "role" => "assistant", "content" => [{ "type" => "text", "text" => "Hi there" }] },
      ],
      "metadata" => { "tool_name" => "claude_code" }
    }.merge(overrides)
  end

  describe ".validate" do
    it "returns no errors for valid data" do
      errors = described_class.validate(valid_data)
      expect(errors).to be_empty
    end

    it "returns no errors when metadata is missing" do
      data = valid_data.except("metadata")
      errors = described_class.validate(data)
      expect(errors).to be_empty
    end

    it "returns error when data is not a Hash" do
      errors = described_class.validate([])
      expect(errors.size).to eq(1)
      expect(errors.first.message).to include("JSON object")
    end

    it "returns error when messages key is missing" do
      errors = described_class.validate({ "metadata" => {} })
      expect(errors.size).to eq(1)
      expect(errors.first.message).to include("Missing required key: messages")
    end

    it "returns error when messages is not an array" do
      errors = described_class.validate({ "messages" => "not an array" })
      expect(errors.size).to eq(1)
      expect(errors.first.message).to include("messages must be an array")
    end

    it "returns error when metadata is not a Hash" do
      errors = described_class.validate({ "messages" => [], "metadata" => "string" })
      expect(errors.size).to eq(1)
      expect(errors.first.message).to include("metadata must be a JSON object")
    end

    it "returns error for messages with invalid role" do
      data = valid_data("messages" => [
                          { "role" => "system", "content" => [{ "type" => "text", "text" => "x" }] },
                        ])
      errors = described_class.validate(data)
      expect(errors.size).to eq(1)
      expect(errors.first.message).to include("invalid role")
    end

    it "returns error for messages without content array" do
      data = valid_data("messages" => [
                          { "role" => "user", "content" => "not an array" },
                        ])
      errors = described_class.validate(data)
      expect(errors.size).to eq(1)
      expect(errors.first.message).to include("must have a content array")
    end

    it "returns error for content blocks with invalid type" do
      data = valid_data("messages" => [
                          { "role" => "user", "content" => [{ "type" => "image", "url" => "x" }] },
                        ])
      errors = described_class.validate(data)
      expect(errors.size).to eq(1)
      expect(errors.first.message).to include("invalid type")
    end

    it "accepts tool_call content blocks" do
      data = valid_data("messages" => [
                          { "role" => "assistant", "content" => [
                            { "type" => "tool_call", "name" => "Read", "input" => "/path" },
                          ] },
                        ])
      errors = described_class.validate(data)
      expect(errors).to be_empty
    end

    it "returns error when too many messages" do
      messages = Array.new(50_001) do |i|
        { "role" => "user", "content" => [{ "type" => "text", "text" => "msg #{i}" }] }
      end
      errors = described_class.validate({ "messages" => messages })
      expect(errors.size).to eq(1)
      expect(errors.first.message).to include("Too many messages")
    end

    it "limits errors to a reasonable number per validation" do
      messages = Array.new(100) { { "role" => "bad" } }
      errors = described_class.validate({ "messages" => messages })
      expect(errors.size).to be <= 10
      expect(errors.size).to be < 100
    end
  end
end
