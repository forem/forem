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
    it "purges its trend on create" do
      trend = create(:trend)
      article = create(:article)
      membership = build(:trend_membership, trend: trend, article: article)

      expect(trend).to receive(:purge)
      expect(trend).to receive(:purge_all)
      membership.save!
    end

    it "purges its trend on update" do
      trend = create(:trend)
      membership = create(:trend_membership, trend: trend)

      expect(trend).to receive(:purge)
      expect(trend).to receive(:purge_all)
      membership.update!(distance: 0.99)
    end

    it "purges its trend on destroy" do
      trend = create(:trend)
      membership = create(:trend_membership, trend: trend)

      expect(trend).to receive(:purge)
      expect(trend).to receive(:purge_all)
      membership.destroy!
    end
  end
end
