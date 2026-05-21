require "rails_helper"

RSpec.describe TrendMembership do
  let(:trend_membership) { build(:trend_membership) }

  describe "associations" do
    it "belongs to a trend" do
      expect(trend_membership.trend).to be_present
    end

    it "belongs to an article" do
      expect(trend_membership.article).to be_present
    end
  end

  describe "validations" do
    it "is valid with valid attributes" do
      expect(trend_membership).to be_valid
    end

    it "is invalid without distance" do
      trend_membership.distance = nil
      expect(trend_membership).not_to be_valid
    end
  end
end
