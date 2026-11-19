require "rails_helper"

RSpec.describe AgentSessionParsers::RedactionMetadata do
  describe ".for_scrub_result" do
    let(:scrubber) { AgentSessionParsers::SensitiveDataScrubber }
    let(:messages) do
      rows = [{ "name" => "First", "count" => 1 }, { "name" => "Second", "count" => 2 }]
      [{ "metadata" => { "redactions" => rows } }]
    end
    let(:server_redactions) { [scrubber::Redaction.new(pattern_name: "First", match_count: 1)] }

    it "prefers session-wide counts and preserves the rest of the metadata" do
      metadata = { "redactions" => [{ "name" => "First", "count" => 3 }], "tool_name" => "codex" }
      result = scrubber::Result.new(scrubbed_data: { "messages" => messages, "metadata" => metadata },
                                    redactions: server_redactions)

      expect(described_class.for_scrub_result(result))
        .to eq({ "redactions" => [{ "name" => "First", "count" => 4 }], "tool_name" => "codex" })
      expect(metadata["redactions"]).to eq([{ "name" => "First", "count" => 3 }])
    end

    it "preserves client report ordering when server counts create a tie" do
      result = scrubber::Result.new(scrubbed_data: { "messages" => messages }, redactions: server_redactions)
      expected = { "redactions" => [{ "name" => "Second", "count" => 2 }, { "name" => "First", "count" => 2 }] }

      expect(described_class.for_scrub_result(result)).to eq(expected)
      allow(ForemNative::Native).to receive(:respond_to?).with(:aggregate_transcript_redactions).and_return(false)
      expect(described_class.for_scrub_result(result)).to eq(expected)
    end
  end

  describe ".merge" do
    it "preserves client-side redaction counts" do
      result = described_class.merge(
        [{ "name" => "GitHub Token", "count" => 2 }],
        [],
      )

      expect(result).to eq([{ "name" => "GitHub Token", "count" => 2 }])
    end

    it "accepts JavaScript scrubber redaction keys" do
      result = described_class.merge(
        [{ "pattern_name" => "Home Directory", "match_count" => 1 }],
        [],
      )

      expect(result).to eq([{ "name" => "Home Directory", "count" => 1 }])
    end

    it "combines client and server redaction counts" do
      redaction = Struct.new(:pattern_name, :match_count)
      result = described_class.merge(
        [{ "name" => "GitHub Token", "count" => 1 }],
        [redaction.new("GitHub Token", 2), redaction.new("AWS Access Key", 1)],
      )

      expected = [
        { "name" => "GitHub Token", "count" => 3 },
        { "name" => "AWS Access Key", "count" => 1 },
      ]
      expect(result).to eq(expected)
    end
  end

  describe ".from_messages" do
    it "aggregates redactions from message metadata" do
      messages = [
        { "metadata" => { "redactions" => [{ "pattern_name" => "GitHub Token", "match_count" => 1 }] } },
        { "metadata" => { "redactions" => [{ "name" => "GitHub Token", "count" => 2 }] } },
        { "metadata" => { "redactions" => [{ "name" => "Home Directory", "count" => 1 }] } },
      ]

      expected = [
        { "name" => "GitHub Token", "count" => 3 },
        { "name" => "Home Directory", "count" => 1 },
      ]
      expect(described_class.from_messages(messages)).to eq(expected)
    end
  end
end
