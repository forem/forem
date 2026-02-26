require "rails_helper"

RSpec.describe AgentSessionParsers::SensitiveDataScrubber do
  def build_normalized(text_content, tool_output: nil)
    content = [{ "type" => "text", "text" => text_content }]
    if tool_output
      content << { "type" => "tool_call", "name" => "Bash", "input" => "run cmd", "output" => tool_output }
    end
    { "messages" => [{ "index" => 0, "role" => "assistant", "content" => content }], "metadata" => {} }
  end

  describe ".scrub" do
    it "redacts AWS access keys" do
      data = build_normalized("My key is AKIAIOSFODNN7EXAMPLE and it works")
      result = described_class.scrub(data)
      text = result.scrubbed_data["messages"][0]["content"][0]["text"]
      expect(text).to include("[REDACTED]")
      expect(text).not_to include("AKIAIOSFODNN7EXAMPLE")
      expect(result.redactions.map(&:pattern_name)).to include("AWS Access Key")
    end

    it "redacts GitHub tokens" do
      data = build_normalized("token: ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijkl")
      result = described_class.scrub(data)
      text = result.scrubbed_data["messages"][0]["content"][0]["text"]
      expect(text).to include("[REDACTED]")
      expect(text).not_to include("ghp_ABCDEFGHIJKLMNOP")
    end

    it "redacts Stripe secret keys" do
      # Build key via interpolation so the literal doesn't trigger GitHub push protection
      stripe_key = "sk_live_#{'a1b2c3d4e5' * 3}"
      data = build_normalized("STRIPE_KEY=#{stripe_key}")
      result = described_class.scrub(data)
      text = result.scrubbed_data["messages"][0]["content"][0]["text"]
      expect(text).not_to include(stripe_key)
      expect(text).to include("[REDACTED]")
    end

    it "redacts database URLs with credentials" do
      data = build_normalized("DATABASE_URL=postgres://admin:s3cret@db.example.com:5432/mydb")
      result = described_class.scrub(data)
      text = result.scrubbed_data["messages"][0]["content"][0]["text"]
      expect(text).not_to include("s3cret")
      expect(text).not_to include("admin:")
    end

    it "redacts private key headers" do
      data = build_normalized("-----BEGIN RSA PRIVATE KEY-----\nMIIEpA...")
      result = described_class.scrub(data)
      text = result.scrubbed_data["messages"][0]["content"][0]["text"]
      expect(text).to include("[REDACTED]")
      expect(text).not_to include("BEGIN RSA PRIVATE KEY")
    end

    it "redacts OpenAI project keys" do
      data = build_normalized("OPENAI_API_KEY=sk-proj-abcdefghijklmnopqrstuvwxyz1234567890abcdef")
      result = described_class.scrub(data)
      text = result.scrubbed_data["messages"][0]["content"][0]["text"]
      expect(text).not_to include("sk-proj-")
    end

    it "redacts Anthropic API keys" do
      data = build_normalized("key: sk-ant-abcdefghijklmnopqrstuvwxyz1234567890abcdefgh")
      result = described_class.scrub(data)
      text = result.scrubbed_data["messages"][0]["content"][0]["text"]
      expect(text).not_to include("sk-ant-")
    end

    it "redacts Slack tokens" do
      data = build_normalized("SLACK_TOKEN=xoxb-1234567890-abcdef-ghijklmno")
      result = described_class.scrub(data)
      text = result.scrubbed_data["messages"][0]["content"][0]["text"]
      expect(text).not_to include("xoxb-")
    end

    it "redacts JWT tokens" do
      jwt = "eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxfQ.abc123def456_ghi789"
      data = build_normalized("Authorization: Bearer #{jwt}")
      result = described_class.scrub(data)
      text = result.scrubbed_data["messages"][0]["content"][0]["text"]
      expect(text).not_to include("eyJhbGciOiJIUzI1NiJ9")
    end

    it "redacts home directory paths" do
      data = build_normalized("Reading /Users/johnsmith/.ssh/config")
      result = described_class.scrub(data)
      text = result.scrubbed_data["messages"][0]["content"][0]["text"]
      expect(text).not_to include("johnsmith")
    end

    it "scrubs tool call input and output fields" do
      data = build_normalized("normal text", tool_output: "key=AKIAIOSFODNN7EXAMPLE")
      result = described_class.scrub(data)
      output = result.scrubbed_data["messages"][0]["content"][1]["output"]
      expect(output).to include("[REDACTED]")
      expect(output).not_to include("AKIAIOSFODNN7EXAMPLE")
    end

    it "does not modify text without secrets" do
      data = build_normalized("Just a normal conversation about code")
      result = described_class.scrub(data)
      text = result.scrubbed_data["messages"][0]["content"][0]["text"]
      expect(text).to eq("Just a normal conversation about code")
      expect(result.redactions).to be_empty
    end

    it "counts redactions correctly across multiple occurrences" do
      data = build_normalized("AKIAIOSFODNN7EXAMPLE and AKIAIOSFODNN7EXAMPL2")
      result = described_class.scrub(data)
      aws_redaction = result.redactions.detect { |r| r.pattern_name == "AWS Access Key" }
      expect(aws_redaction.match_count).to eq(2)
    end

    it "does not mutate the original data" do
      original_text = "key: ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijkl"
      data = build_normalized(original_text)
      original_content = data["messages"][0]["content"][0]["text"].dup
      described_class.scrub(data)
      expect(data["messages"][0]["content"][0]["text"]).to eq(original_content)
    end
  end

  describe ".scrub_text" do
    it "scrubs secrets from plain text" do
      text = "export AWS_KEY=AKIAIOSFODNN7EXAMPLE\nexport OTHER=safe"
      result = described_class.scrub_text(text)
      expect(result).not_to include("AKIAIOSFODNN7EXAMPLE")
      expect(result).to include("safe")
    end
  end
end
