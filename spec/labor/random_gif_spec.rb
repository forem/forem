require "rails_helper"

RSpec.describe RandomGif, type: :labor do
  describe "#random_id" do
    it "returns a random gif ID from RANDOM_GIFS" do
      id_options = described_class::RANDOM_GIFS.keys
      expect(id_options).to include(described_class.random_id)
    end
  end

  describe "#get_aspect_ratio" do
    it "returns aspect ratio for given ID" do
      gif_id = described_class.random_id
      aspect_ratio = described_class::RANDOM_GIFS.dig(gif_id, :aspect_ratio)
      expect(described_class.get_aspect_ratio(gif_id)).to eq(aspect_ratio)
    end

    it "returns default 1.00 when gif ID is not present" do
      expect(described_class.get_aspect_ratio("not_there")).to eq(described_class::DEFAULT_RATIO)
    end
  end
end
