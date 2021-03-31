require "rails_helper"

RSpec.describe Role, type: :model do
  it { is_expected.to belong_to(:resource).optional }
  it { is_expected.to validate_inclusion_of(:resource_type).in_array(Rolify.resource_types) }
  it { is_expected.to validate_inclusion_of(:name).in_array(described_class::ROLES) }

  describe "::ROLES" do
    it "contains the correct values" do
      expected_roles = %w[
        admin banned chatroom_beta_tester codeland_admin comment_banned podcast_admin restricted_liquid_tag
        single_resource_admin super_admin tag_moderator mod_relations_admin support_admin tech_admin trusted
        warned workshop_pass
      ]
      expect(described_class::ROLES).to eq(expected_roles)
    end
  end
end
