require "rails_helper"

RSpec.describe FlagAppeal, type: :model do
  let(:user) { create(:user) }
  let(:flag_appeal) { build(:flag_appeal, user: user, appealable: user) }

  describe "validations" do
    it "is valid with valid attributes" do
      expect(flag_appeal).to be_valid
    end

    it "is invalid without a reason" do
      flag_appeal.reason = nil
      expect(flag_appeal).not_to be_valid
    end

    it "is invalid if reason exceeds 3000 characters" do
      flag_appeal.reason = "a" * 3001
      expect(flag_appeal).not_to be_valid
    end

    it "is invalid if a pending appeal already exists for the target" do
      flag_appeal.save!
      duplicate = build(:flag_appeal, user: user, appealable: user)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:base]).to include("You already have an open appeal pending review for this item.")
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:appealable) }
    it { is_expected.to belong_to(:resolved_by).class_name("User").optional }
  end

  describe "enums" do
    it "defines status enum" do
      expect(described_class.statuses).to include("open", "ai_reviewed", "approved", "rejected")
    end

    it "defines ai_recommendation enum" do
      expect(described_class.ai_recommendations).to include("auto_unflag", "human_review", "confirm_flag")
    end
  end
end
