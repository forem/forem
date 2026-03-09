require "rails_helper"

RSpec.describe Ai::LiquidTagGuide do
  describe ".guide_text" do
    it "returns a string containing liquid tag syntax" do
      result = described_class.guide_text
      expect(result).to be_a(String)
      expect(result).to include("embed")
      expect(result.length).to be > 100
    end

    it "includes URL embed information" do
      result = described_class.guide_text
      expect(result).to include("YouTube")
    end

    it "includes non-URL embed information" do
      result = described_class.guide_text
      expect(result).to include("details")
    end

    it "caches the result" do
      Rails.cache.clear
      first_call = described_class.guide_text
      second_call = described_class.guide_text
      expect(first_call).to eq(second_call)
    end

    it "strips ERB tags from the output" do
      result = described_class.guide_text
      expect(result).not_to include("<%")
      expect(result).not_to include("%>")
    end

    it "strips HTML tags from the main guide section" do
      result = described_class.guide_text
      expect(result).not_to match(/<h[1-6][^>]*>/)
      expect(result).not_to match(/<div[^>]*>/)
    end
  end
end
