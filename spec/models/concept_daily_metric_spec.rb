require "rails_helper"

RSpec.describe ConceptDailyMetric, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      metric = build(:concept_daily_metric)
      expect(metric).to be_valid
    end

    it "requires concept_id, date, and numerical values" do
      metric = build(:concept_daily_metric, concept_id: nil)
      expect(metric).not_to be_valid

      metric = build(:concept_daily_metric, date: nil)
      expect(metric).not_to be_valid

      metric = build(:concept_daily_metric, articles_count: -1)
      expect(metric).not_to be_valid

      metric = build(:concept_daily_metric, popularity_score: -0.5)
      expect(metric).not_to be_valid
    end

    it "enforces uniqueness of date scoped to concept_id" do
      concept = create(:concept)
      date = Date.today
      create(:concept_daily_metric, concept: concept, date: date)

      duplicate = build(:concept_daily_metric, concept: concept, date: date)
      expect(duplicate).not_to be_valid
    end
  end
end
