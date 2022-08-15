require "rails_helper"

RSpec.describe Moderator::ManageActivityAndRoles, type: :service do
  let(:user) { create(:user) }
  let(:admin) { create(:user, :super_admin) }

  it "updates user status" do
    user.add_role(:suspended)
    user.reload
    described_class.handle_user_roles(
      admin: admin,
      user: user,
      user_params: { note_for_current_role: "warning user", user_status: "Warned" },
    )
    expect(user.warned?).to be true
    expect(user.suspended?).to be false
  end

  it "updates user to super admin" do
    described_class.handle_user_roles(
      admin: admin,
      user: user,
      user_params: { note_for_current_role: "Upgrading to super admin", user_status: "Super Admin" },
    )
    expect(user.super_admin?).to be true
  end

  it "assigns trusted role to user that's updated to super admin" do
    described_class.handle_user_roles(
      admin: admin,
      user: user,
      user_params: { note_for_current_role: "Upgrading to super admin", user_status: "Super Admin" },
    )
    expect(user.super_admin?).to be true
    expect(user.has_trusted_role?).to be true
  end

  it "updates user to admin" do
    described_class.handle_user_roles(
      admin: admin,
      user: user,
      user_params: { note_for_current_role: "Upgrading to admin", user_status: "Admin" },
    )
    expect(user.admin?).to be true
  end

  it "assigns trusted role to user that's updated to admin" do
    described_class.handle_user_roles(
      admin: admin,
      user: user,
      user_params: { note_for_current_role: "Upgrading to admin", user_status: "Admin" },
    )
    expect(user.admin?).to be true
    expect(user.has_trusted_role?).to be true
  end

  it "updates user to tech admin" do
    described_class.handle_user_roles(
      admin: admin,
      user: user,
      user_params: { note_for_current_role: "Upgrading to tech admin", user_status: "Tech Admin" },
    )
    expect(user.tech_admin?).to be true
    expect(user.single_resource_admin_for?(DataUpdateScript)).to be true
  end

  it "updates user to single resource admin" do
    described_class.handle_user_roles(
      admin: admin,
      user: user,
      user_params: { note_for_current_role: "Upgrading to super admin", user_status: "Resource Admin: Article" },
    )
    expect(user.single_resource_admin_for?(Article)).to be true
  end

  it "updates negative role to positive role" do
    user.add_role(:comment_suspended)
    described_class.handle_user_roles(
      admin: admin,
      user: user,
      user_params: { note_for_current_role: "user in good standing", user_status: "Good standing" },
    )
    expect(user.suspended?).to be false
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

    it "updates user to super moderator" do
      expect do
        described_class.handle_user_roles(
          admin: admin,
          user: user,
          user_params: { note_for_current_role: "Upgrading to super_moderator", user_status: "Super Moderator" },
        )
      end.to raise_error(StandardError)
    end
  end
end
