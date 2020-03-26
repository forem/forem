require "rails_helper"

RSpec.describe SponsorshipDecorator, type: :decorator do
  context "with serialization" do
    let_it_be_readonly(:sponsorship) { create(:sponsorship).decorate }

    it "serializes both the decorated object IDs and decorated methods" do
      expected_result = { "id" => sponsorship.id, "level_background_color" => sponsorship.level_background_color }
      expect(sponsorship.as_json(only: [:id], methods: [:level_background_color])).to eq(expected_result)
    end

    it "serializes collections of decorated objects" do
      decorated_collection = Sponsorship.decorate
      expected_result = [{ "id" => sponsorship.id, "level_background_color" => sponsorship.level_background_color }]
      expect(decorated_collection.as_json(only: [:id], methods: [:level_background_color])).to eq(expected_result)
    end
  end

  describe "#level_background_color" do
    let(:sponsorship) { build(:sponsorship) }

    it "returns the correct hex for gold" do
      sponsorship.level = "gold"
      expected_result = "linear-gradient(to right, #faf0e6 8%, #faf3e6 18%, #fcf6eb 33%);"
      expect(sponsorship.decorate.level_background_color).to eq(expected_result)
    end

    it "returns empty string for unsupported level" do
      sponsorship.level = "media"
      expect(sponsorship.decorate.level_background_color).to eq("")
    end
  end
end
