require "rails_helper"

RSpec.describe SponsorshipDecorator, type: :decorator do
  describe "#level_color_hex" do
    let(:sponsorship) { build(:sponsorship) }

    it "returns the correct hex for gold" do
      sponsorship.level = "gold"
      expected_result = "linear-gradient(to right, #faf0e6 8%, #faf3e6 18%, #fcf6eb 33%);"
      expect(sponsorship.decorate_.level_color_hex).to eq(expected_result)
    end

    it "returns empty string for unsupported level" do
      sponsorship.level = "media"
      expect(sponsorship.decorate_.level_color_hex).to eq("")
    end
  end
end
