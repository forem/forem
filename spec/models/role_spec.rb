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

  describe "#resource_name" do
    let(:user) { create(:user) }

    it "returns the resource type when there is no resource id" do
      role = described_class.new(name: "single_resource_admin", resource_type: "Badge")

      expect(role.resource_name).to eq("Badge")
    end

    it "returns nil when there is no resource at all" do
      expect(described_class.new(name: "admin").resource_name).to be_nil
    end

    it "returns the tag name for a tag moderator role" do
      tag = create(:tag)
      user.add_role(:tag_moderator, tag)

      expect(user.roles.find_by(name: "tag_moderator").resource_name).to eq(tag.name)
    end

    it "returns the subforem domain for a subforem moderator role" do
      subforem = create(:subforem)
      user.add_role(:subforem_moderator, subforem)

      expect(user.roles.find_by(name: "subforem_moderator").resource_name).to eq(subforem.domain)
    end

    it "does not return an unrelated tag's name when a subforem shares the tag's id" do
      tag = create(:tag)
      subforem = create(:subforem, id: tag.id)
      user.add_role(:subforem_moderator, subforem)

      expect(user.roles.find_by(name: "subforem_moderator").resource_name).to eq(subforem.domain)
    end

    it "returns the podcast title for a podcast admin role" do
      podcast = create(:podcast)
      user.add_role(:podcast_admin, podcast)

      expect(user.roles.find_by(name: "podcast_admin").resource_name).to eq(podcast.title)
    end

    it "returns the role name for a role scoped to another role" do
      scoped_to = create(:role, name: "trusted")
      role = described_class.new(name: "single_resource_admin", resource: scoped_to)

      expect(role.resource_name).to eq("trusted")
    end

    it "falls back to the type and id when the resource no longer exists" do
      podcast = create(:podcast)
      user.add_role(:podcast_admin, podcast)
      role = user.roles.find_by(name: "podcast_admin")
      podcast.delete

      expect(role.reload.resource_name).to eq("Podcast ##{podcast.id}")
    end

    it "looks up a tag for a legacy role with a resource id but no resource type" do
      tag = create(:tag)
      role = create(:role, name: "tag_moderator", resource_id: tag.id)

      expect(role.resource_name).to eq(tag.name)
    end

    it "does not raise for a legacy role whose tag no longer exists" do
      role = create(:role, name: "tag_moderator", resource_id: Tag.maximum(:id).to_i + 1)

      expect(role.resource_name).to be_nil
    end
  end
end
