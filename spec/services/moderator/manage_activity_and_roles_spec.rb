require "rails_helper"

RSpec.describe Moderator::ManageActivityAndRoles, type: :service do
  let(:user) { create(:user) }
  let(:admin) { create(:user, :super_admin) }

  it "updates user status" do
    user.add_role(:banned)
    user.reload
    described_class.handle_user_roles(
      admin: admin,
      user: user,
      user_params: { note_for_current_role: "warning user", user_status: "Warn" },
    )
    expect(user.warned).to be true
    expect(user.banned).to be false
  end

  it "updates user to super admin" do
    described_class.handle_user_roles(
      admin: admin,
      user: user,
      user_params: { note_for_current_role: "Upgrading to super admin", user_status: "Super Admin" },
    )
    expect(user.has_role?(:super_admin)).to be true
  end

  it "updates user to admin" do
    described_class.handle_user_roles(
      admin: admin,
      user: user,
      user_params: { note_for_current_role: "Upgrading to super admin", user_status: "Admin" },
    )
    expect(user.has_role?(:admin)).to be true
  end

  it "updates user to tech admin" do
    described_class.handle_user_roles(
      admin: admin,
      user: user,
      user_params: { note_for_current_role: "Upgrading to tech admin", user_status: "Tech Admin" },
    )
    expect(user.has_role?(:tech_admin)).to be true
    expect(user.has_role?(:single_resource_admin, DataUpdateScript)).to be true
  end

  it "updates user to single resource admin" do
    described_class.handle_user_roles(
      admin: admin,
      user: user,
      user_params: { note_for_current_role: "Upgrading to super admin", user_status: "Resource Admin: Article" },
    )
    expect(user.has_role?(:single_resource_admin, Article)).to be true
  end

  it "updates negative role to positive role" do
    user.add_role(:comment_banned)
    described_class.handle_user_roles(
      admin: admin,
      user: user,
      user_params: { note_for_current_role: "user in good standing", user_status: "Regular Member" },
    )
    expect(user.banned).to be false
    expect(user.roles.count).to eq(0)
  end

  context "when not super admin" do
    before do
      admin.remove_role(:super_admin)
      admin.add_role(:admin)
    end

    it "updates user to super admin" do
      expect do
        described_class.handle_user_roles(
          admin: admin,
          user: user,
          user_params: { note_for_current_role: "Upgrading to super admin", user_status: "Super Admin" },
        )
      end.to raise_error(StandardError)
    end

    it "updates user to admin" do
      expect do
        described_class.handle_user_roles(
          admin: admin,
          user: user,
          user_params: { note_for_current_role: "Upgrading to super admin", user_status: "Admin" },
        )
      end.to raise_error(StandardError)
    end

    it "updates user to single resource admin" do
      expect do
        described_class.handle_user_roles(
          admin: admin,
          user: user,
          user_params: { note_for_current_role: "Upgrading to super admin", user_status: "Resource Admin: Article" },
        )
      end.to raise_error(StandardError)
    end
  end
end
