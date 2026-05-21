require "rails_helper"

RSpec.describe DataFixes::Registry do
  describe ".fetch!" do
    it "returns the fix class for a known key" do
      expect(described_class.fetch!(DataFixes::FixTagCounts::KEY)).to eq(DataFixes::FixTagCounts)
    end

    it "raises ArgumentError for an unknown key" do
      expect { described_class.fetch!("nonexistent") }.to raise_error(ArgumentError, /Unknown data fix/)
    end
  end

  describe ".fetch_check!" do
    it "returns the check class for a known key" do
      expect(described_class.fetch_check!(DataFixes::VerifyTagCounts::KEY)).to eq(DataFixes::VerifyTagCounts)
    end

    it "raises ArgumentError for an unknown key" do
      expect { described_class.fetch_check!("nonexistent") }.to raise_error(ArgumentError, /Unknown data check/)
    end
  end
end
