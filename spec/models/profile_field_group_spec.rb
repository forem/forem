require "rails_helper"

RSpec.describe ProfileFieldGroup, type: :model do
  let!(:group) { create(:profile_field_group) }
  subject { group }

  it { is_expected.to have_many(:profile_fields).dependent(:nullify) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_uniqueness_of(:name) }

  describe ".onboarding" do
    let!(:other_group) { create(:profile_field_group) }
    let!(:profile_field1) { create(:profile_field, :onboarding, profile_field_group: group) }
    let!(:profile_field2) { create(:profile_field, profile_field_group: other_group) }

    it "only returns groups that have fields for onboarding" do
      groups = described_class.onboarding
      expect(groups).to include(group)
      expect(groups).not_to include(other_group)
    end
  end
end
