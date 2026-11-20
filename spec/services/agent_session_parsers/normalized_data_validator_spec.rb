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
    it "accepts the exact size limit and rejects one additional encoded byte" do
      data = valid_data("metadata" => { "text" => "<>&😀\u2028" })
      size = data.to_json.bytesize
      stub_const("AgentSessionParsers::NormalizedDataValidator::MAX_JSON_SIZE", size)
      expect(described_class.validate(data)).to be_empty

      data["metadata"]["text"] << "a"
      expect(described_class.validate(data).map(&:message))
        .to eq(["Normalized data is too large (#{size + 1} bytes, max #{size})"])
    end

    it "avoids serializing a supported transcript into a temporary JSON string" do
      instance = described_class.new(valid_data)
      allow(instance).to receive(:legacy_json_size).and_call_original
      expect(instance.validate).to be_empty
      expect(instance).not_to have_received(:legacy_json_size)
    end

    it "honors a stubbed to_json through the legacy path" do
      data = valid_data
      allow(data).to receive(:to_json).and_return("x" * (described_class::MAX_JSON_SIZE + 1))
      expect(described_class.validate(data).first.message).to include("Normalized data is too large")
    end

    it "uses the configured HTML escaping policy" do
      data = valid_data("metadata" => { "html" => "<>&" })
      allow(ActiveSupport::JSON::Encoding).to receive(:escape_html_entities_in_json).and_return(false)
      expect(described_class.new(data).__send__(:native_json_size)).to eq(data.to_json.bytesize)
    end

    it "defers to a custom JSON encoder" do
      encoder = Class.new(ActiveSupport::JSON::Encoding::JSONGemEncoder)
      allow(ActiveSupport::JSON::Encoding).to receive(:json_encoder).and_return(encoder)
      data = valid_data
      allow(ForemNative).to receive(:json_encoded_size).and_call_original
      expect(described_class.validate(data)).to be_empty
      expect(ForemNative).not_to have_received(:json_encoded_size)
    end

    it "accepts exactly 10 MB and reports the exact oversized byte count" do
      data = valid_data("metadata" => { "text" => "" })
      limit = described_class::MAX_JSON_SIZE
      data["metadata"]["text"] = "a" * (limit - data.to_json.bytesize)
      expect(ForemNative.json_encoded_size(data)).to eq(limit)
      expect(described_class.validate(data)).to be_empty

      data["metadata"]["text"] << "a"
      expect(described_class.validate(data).map(&:message))
        .to eq(["Normalized data is too large (#{limit + 1} bytes, max #{limit})"])
    end

    it "uses legacy serialization when a platform binary lacks the counting symbol" do
      allow(ForemNative::Native).to receive(:respond_to?).with(:json_encoded_size).and_return(false)
      data = valid_data
      instance = described_class.new(data)
      allow(instance).to receive(:legacy_json_size).and_call_original
      expect(instance.validate).to be_empty
      expect(instance).to have_received(:legacy_json_size)
    end

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
