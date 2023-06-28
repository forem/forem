require "rails_helper"

RSpec.describe OrganizationMembership do
  describe "validations" do
    subject { build(:organization_membership) }

    let(:organization) { create(:organization) }

    it { is_expected.to validate_presence_of(:type_of_user) }
    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:organization_id) }
    it { is_expected.to validate_inclusion_of(:type_of_user).in_array(OrganizationMembership::USER_TYPES) }
  end
end
