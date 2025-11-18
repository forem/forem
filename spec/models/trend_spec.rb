require "rails_helper"

RSpec.describe Trend do
  let(:subforem) { create(:subforem) }
  let(:trend) { create(:trend, subforem: subforem) }

  describe "validations" do
    it "validates presence of short_title" do
      trend.short_title = nil
      expect(trend).not_to be_valid
      expect(trend.errors[:short_title]).to be_present
    end

    it "validates length of short_title" do
      trend.short_title = "a" * 76
      expect(trend).not_to be_valid
      expect(trend.errors[:short_title]).to be_present
    end

    it "validates presence of public_description" do
      trend.public_description = nil
      expect(trend).not_to be_valid
      expect(trend.errors[:public_description]).to be_present
    end

    it "validates presence of full_content_description" do
      trend.full_content_description = nil
      expect(trend).not_to be_valid
      expect(trend.errors[:full_content_description]).to be_present
    end

    it "validates presence of expiry_date" do
      trend.expiry_date = nil
      expect(trend).not_to be_valid
      expect(trend.errors[:expiry_date]).to be_present
    end
  end

  describe "associations" do
    it "belongs to a subforem" do
      expect(trend.subforem).to eq(subforem)
    end

    it "has many context_notes" do
      context_note = create(:context_note, trend: trend)
      expect(trend.context_notes).to include(context_note)
    end
  end

  describe "scopes" do
    let!(:current_trend) { create(:trend, subforem: subforem, expiry_date: 1.month.from_now) }
    let!(:expired_trend) { create(:trend, subforem: subforem, expiry_date: 1.month.ago) }

    it "returns only current trends" do
      expect(Trend.current).to include(current_trend)
      expect(Trend.current).not_to include(expired_trend)
    end

    it "returns trends for a specific subforem" do
      other_subforem = create(:subforem)
      other_trend = create(:trend, subforem: other_subforem)

      expect(Trend.for_subforem(subforem.id)).to include(current_trend)
      expect(Trend.for_subforem(subforem.id)).not_to include(other_trend)
    end
  end

  describe "#expired?" do
    it "returns true for expired trends" do
      trend.expiry_date = 1.day.ago
      expect(trend.expired?).to be true
    end

    it "returns false for current trends" do
      trend.expiry_date = 1.day.from_now
      expect(trend.expired?).to be false
    end
  end

  describe "#current?" do
    it "returns true for current trends" do
      trend.expiry_date = 1.day.from_now
      expect(trend.current?).to be true
    end

    it "returns false for expired trends" do
      trend.expiry_date = 1.day.ago
      expect(trend.current?).to be false
    end
  end
end

