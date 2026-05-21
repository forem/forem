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

  describe "callbacks" do
    it "registers #purge_trend as an after_commit callback" do
      callback_names = TrendMembership._commit_callbacks.select { |cb| cb.kind == :after }.map(&:filter)
      expect(callback_names).to include(:purge_trend)
    end
  end

  describe "#purge_trend" do
    it "purges its associated trend" do
      trend = double("Trend")
      membership = build(:trend_membership)
      allow(membership).to receive(:trend).and_return(trend)

      expect(trend).to receive(:purge)
      membership.send(:purge_trend)
    end
  end
end
