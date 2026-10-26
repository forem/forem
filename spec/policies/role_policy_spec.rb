require "rails_helper"

describe RolePolicy do
  subject(:role) { described_class }

  let(:role_suspended) { build(:role, name: "suspended") }
  let(:role_trusted) { build(:role, name: "trusted") }
  let(:role_super_admin) { build(:role, name: "super_admin") }
  let(:role_community_leader_l1) { build(:role, name: "community_leader_level_1") }
  let(:role_community_leader_l2) { build(:role, name: "community_leader_level_2") }
  let(:super_admin_user) { build(:user, :super_admin) }
  let(:admin_user) { build(:user, :admin) }

  permissions :remove_role? do
    it "allows access for super_admin if the role is suspended" do
      expect(role).to permit(super_admin_user, role_suspended)
    end

    it "grants access if user is super admin" do
      expect(role).to permit(super_admin_user, role_trusted)
    end

    it "denies access if user is admin and role is super_admin" do
      expect(role).not_to permit(admin_user, role_super_admin)
    end

    it "allows access if user is admin and role is community_leader_level_1" do
      expect(role).to permit(admin_user, role_community_leader_l1)
    end

    it "denies access if user is admin and role is community_leader_level_2" do
      expect(role).not_to permit(admin_user, role_community_leader_l2)
    end

    it "allows access if user is super_admin and role is community_leader_level_2" do
      expect(role).to permit(super_admin_user, role_community_leader_l2)
    end
  end
end
