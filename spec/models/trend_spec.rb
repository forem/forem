require "rails_helper"

RSpec.describe Trend do
  let(:trend) { build(:trend) }

  describe "validations" do
    it "is valid with valid attributes" do
      expect(trend).to be_valid
    end

    it "is invalid without a name" do
      trend.name = nil
      expect(trend).not_to be_valid
    end

    it "is invalid without centroid_embedding" do
      trend.centroid_embedding = nil
      expect(trend).not_to be_valid
    end
  end

  describe "callbacks" do
    it "generates a slug from the name before validation" do
      new_trend = Trend.new(name: "Ruby 3.4 Release", centroid_embedding: Array.new(768, 0.1))
      expect(new_trend).to be_valid
      expect(new_trend.slug).to eq("ruby-3-4-release")
    end
  end

  describe "scopes" do
    describe ".hot_and_recent" do
      it "returns trends ordered by score descending" do
        trend_low = create(:trend, score: 2.0)
        trend_high = create(:trend, score: 20.0)

        expect(Trend.hot_and_recent.to_a).to eq([trend_high, trend_low])
      end
    end
  end
end
