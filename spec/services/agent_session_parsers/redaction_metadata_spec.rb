require "rails_helper"

RSpec.describe AgentSessionParsers::RedactionMetadata do
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

      expect(result).to eq([
        { "name" => "GitHub Token", "count" => 3 },
        { "name" => "AWS Access Key", "count" => 1 },
      ])
    end
  end

  describe ".from_messages" do
    it "aggregates redactions from message metadata" do
      result = described_class.from_messages([
        { "metadata" => { "redactions" => [{ "pattern_name" => "GitHub Token", "match_count" => 1 }] } },
        { "metadata" => { "redactions" => [{ "name" => "GitHub Token", "count" => 2 }] } },
        { "metadata" => { "redactions" => [{ "name" => "Home Directory", "count" => 1 }] } },
      ])

      expect(result).to eq([
        { "name" => "GitHub Token", "count" => 3 },
        { "name" => "Home Directory", "count" => 1 },
      ])
    end
  end
end
