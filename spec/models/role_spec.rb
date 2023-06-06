require "rails_helper"

RSpec.describe Role do
  it { is_expected.to belong_to(:resource).optional }
  it { is_expected.to validate_inclusion_of(:resource_type).in_array(Rolify.resource_types) }
  it { is_expected.to validate_inclusion_of(:name).in_array(described_class::ROLES.values) }

  describe "::ROLES" do
    it "contains the correct values" do
      expected_roles = %w[
        admin codeland_admin comment_suspended mod_relations_admin podcast_admin
        restricted_liquid_tag single_resource_admin super_admin support_admin suspended tag_moderator tech_admin
        trusted warned workshop_pass creator super_moderator
      ]
      expect(described_class::ROLES.values).to match_array(expected_roles)
    end
  end

  describe "#super_admin?" do
    let(:role) { create(:role, name: role_name) }
    let(:role_name) { Role::ROLES[:super_admin] }

    it "has a visible method" do
      expect(role.respond_to?(:super_admin?)).to be true
    end

    it "returns true" do
      expect(role.super_admin?).to be true
    end

    context "with different role" do
      let(:role_name) { Role::ROLES[:admin] }

      it "returns false" do
        expect(role.super_admin?).to be false
      end
    end
  end
end
