require "rails_helper"

RSpec.describe Ai::InterestExtractor do
  describe "#extract" do
    let(:embedding_size) { 768 }
    # specific value to ensure deterministic extraction for testing
    let(:embedding) { Array.new(embedding_size) { |i| i.to_f / embedding_size } } 
    let(:extractor) { described_class.new(embedding) }

    it "returns a hash of interests" do
      result = extractor.extract
      expect(result).to be_a(Hash)
      expect(result.keys).to include("frontend_engineering", "software_architecture", "industry_trends")
      expect(result.keys.size).to eq(described_class::DIMENSIONS.size)
    end

    it "calculates scores for each dimension" do
      result = extractor.extract
      expect(result.values).to all(be_a(Float))
    end
  end

  describe ".dot_product" do
    let(:profile1) { { "frontend_engineering" => 0.5, "backend_engineering" => 0.8 } }
    let(:profile2) { { "frontend_engineering" => 0.5, "backend_engineering" => 0.2 } }

    it "calculates the dot product correctly" do
      # (0.5 * 0.5) + (0.8 * 0.2) = 0.25 + 0.16 = 0.41
      expect(described_class.dot_product(profile1, profile2)).to be_within(0.0001).of(0.41)
    end

    it "returns 0.0 if either profile is blank" do
      expect(described_class.dot_product({}, profile2)).to eq(0.0)
      expect(described_class.dot_product(profile1, nil)).to eq(0.0)
    end
  end
end
