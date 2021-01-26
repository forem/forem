require "rails_helper"

RSpec.describe CustomProfileField, type: :model do
  it_behaves_like "a profile field"

  describe "#validate_maximum_count" do
    it "validates that user's can't have more than 3 custom profile fields" do
      profile = create(:profile)
      create_list(:custom_profile_field, 5, profile: profile)

      custom_profile_field = build(:custom_profile_field, profile: profile)
      custom_profile_field.save

      expect(custom_profile_field).not_to be_valid
      expect(custom_profile_field.errors[:profile_id])
        .to include("maximum number of custom profile fields exceeded")
    end
  end
end
