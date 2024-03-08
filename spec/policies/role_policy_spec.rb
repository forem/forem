require "rails_helper"

describe RolePolicy do
  subject(:role) { described_class }

  let(:role_suspended) { build(:role, name: "suspended") }
  let(:role_trusted) { build(:role, name: "trusted") }
  let(:role_super_admin) { build(:role, name: "super_admin") }
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
  end
end
