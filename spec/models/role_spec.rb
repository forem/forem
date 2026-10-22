require "rails_helper"

RSpec.describe Role do
  it { is_expected.to belong_to(:resource).optional }
  it { is_expected.to validate_inclusion_of(:resource_type).in_array(Rolify.resource_types) }
  it { is_expected.to validate_inclusion_of(:name).in_array(described_class::ROLES) }

  describe "::ROLES" do
    it "contains the correct values" do
      expected_roles = %w[
        admin base_subscriber impending_base_subscriber_cancellation codeland_admin comment_suspended limited podcast_admin
        restricted_liquid_tag single_resource_admin super_admin support_admin suspended spam tag_moderator tech_admin
        trusted warned creator super_moderator subforem_moderator community_leader_level_1 community_leader_level_2
      ]
      expect(described_class::ROLES).to match_array(expected_roles)
    end
  end

  describe "#super_admin?" do
    let(:role) { create(:role, name: role_name) }
    let(:role_name) { "super_admin" }

    it "has a visible method" do
      expect(role.respond_to?(:super_admin?)).to be true
    end

    it "returns true" do
      expect(role.super_admin?).to be true
    end

    context "with different role" do
      let(:role_name) { "admin" }

      it "returns false" do
        expect(role.super_admin?).to be false
      end
    end
  end

  describe "#name_labelize" do
    subject { user.roles.last.name_labelize }

    let(:user) { create(:user, :admin) }

    it { is_expected.to eq "admin" }

    context "when role is single_resource_admin" do
      let(:user) { create(:user, :single_resource_admin, resource: Badge) }

      it { is_expected.to eq "Resource Admin: Badge" }
    end
  end

  describe "as a resource" do
    let(:base_subscriber_role) { described_class.global.find_or_create_by!(name: "base_subscriber") }
    let(:trusted_role) { described_class.global.find_or_create_by!(name: "trusted") }
    let(:user) { create(:user) }

    it { is_expected.to have_many(:scoped_roles).class_name("Role").dependent(:restrict_with_error) }

    it "is a rolify resource type" do
      expect(Rolify.resource_types).to include("Role")
    end

    it "lets a user hold single_resource_admin on one specific role", :aggregate_failures do
      scoped_role = user.add_role(:single_resource_admin, base_subscriber_role)

      expect(scoped_role).to be_persisted
      expect(scoped_role.resource).to eq(base_subscriber_role)
      expect(base_subscriber_role.scoped_roles).to contain_exactly(scoped_role)
      expect(user.single_resource_admin_for?(base_subscriber_role)).to be true
      expect(user.single_resource_admin_for?(trusted_role)).to be false
      expect(Authorizer.for(user: user).administrative_access_to?(resource: base_subscriber_role)).to be true
      expect(Authorizer.for(user: user).administrative_access_to?(resource: trusted_role)).to be false
    end

    it "does not give the user the scoped role itself" do
      user.add_role(:single_resource_admin, base_subscriber_role)

      expect(user.base_subscriber?).to be false
    end

    it "is not destroyed while roles are scoped to it", :aggregate_failures do
      user.add_role(:single_resource_admin, base_subscriber_role)

      expect(base_subscriber_role.destroy).to be false
      expect(described_class.exists?(base_subscriber_role.id)).to be true
    end

    it "keeps the record when its last user loses the role, if roles are scoped to it" do
      subscriber = create(:user)
      subscriber.add_role(:base_subscriber)
      user.add_role(:single_resource_admin, base_subscriber_role)

      subscriber.remove_role(:base_subscriber)

      expect(user.single_resource_admin_for?(described_class.global.find_by(name: "base_subscriber"))).to be true
    end

    it "is still destroyed when its last user loses the role and nothing is scoped to it" do
      subscriber = create(:user)
      subscriber.add_role(:base_subscriber)

      subscriber.remove_role(:base_subscriber)

      expect(described_class.global.find_by(name: "base_subscriber")).to be_nil
    end

    it "uses the role name as the resource name" do
      scoped_role = user.add_role(:single_resource_admin, base_subscriber_role)

      expect(scoped_role.resource_name).to eq("base_subscriber")
    end
  end
end
