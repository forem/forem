require "rails_helper"

RSpec.describe Profile, type: :model do
  describe "validations" do
    subject { create(:profile) }

    it { is_expected.to validate_uniqueness_of(:user_id) }
  end

  context "when accessing profile fields" do
    before do
      create(:profile_field, label: "Test 1")
      create(:profile_field, label: "Test 2", input_type: :check_box)
      create(:profile_field, label: "Test 3", active: false)
      described_class.refresh_store_accessors!
    end

    let(:profile) { described_class.new }

    it "defines accessors for active profile fields", :aggregate_failures do
      expect(profile).to respond_to(:test1)
      expect(profile).to respond_to(:test2)
      expect(profile).not_to respond_to(:test3)
    end

    it "performs ActiveRecord typecasting for profile fields", :aggregate_failures do
      expect do
        profile.test2 = "true"
      end.to change(profile, :test2).from(nil).to(true)

      expect do
        profile.test2 = "f"
      end.to change(profile, :test2).to(false)
    end
  end
end
