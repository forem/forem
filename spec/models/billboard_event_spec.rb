require "rails_helper"

RSpec.describe BillboardEvent do
  it { is_expected.to validate_inclusion_of(:category).in_array(described_class::VALID_CATEGORIES) }

  it { is_expected.to validate_inclusion_of(:context_type).in_array(described_class::VALID_CONTEXT_TYPES) }

  describe "#unique_on_user_if_type_of_conversion_category" do
    let(:user) { create(:user) }
    let(:billboard_event) { build(:billboard_event, category: "signup", user: user) }

    it "adds an error if user has already converted a signup" do
      create(:billboard_event, category: "signup", user: user)
      billboard_event.valid?
      expect(billboard_event.errors[:user_id]).to include("has already converted")
    end

    it "adds an error if user has already converted a conversion" do
      create(:billboard_event, category: "conversion", user: user)
      billboard_event.category = "conversion"
      billboard_event.valid?
      expect(billboard_event.errors[:user_id]).to include("has already converted")
    end

    it "does not add an error if not a signup or conversion" do
      billboard_event.category = "click"
      billboard_event.valid?
      expect(billboard_event.errors[:user_id]).to be_empty
    end
  end

  describe "#only_recent_registrations" do
    let(:user) { create(:user, registered_at: 2.days.ago) }
    let(:billboard_event) { build(:billboard_event, category: "signup", user: user) }

    it "adds an error if user is not a recent registration" do
      billboard_event.valid?
      expect(billboard_event.errors[:user_id]).to include("is not a recent registration")
    end

    it "does not add an error if user is a recent registration" do
      user.update(registered_at: 23.hours.ago)
      billboard_event.valid?
      expect(billboard_event.errors[:user_id]).to be_empty
    end
  end
end
