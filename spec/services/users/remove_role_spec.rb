require "rails_helper"

RSpec.describe Users::RemoveRole, type: :service do
  let(:current_user) { create(:user, :admin) }

  context "when user is a super_admin" do
    it "does not remove super_admin roles and raises an error", :aggregate_failures do
      super_admin = create(:user, :super_admin)
      role = super_admin.roles.first.name.to_sym
      resource_type = nil
      args = { user: super_admin, role: role, resource_type: resource_type, admin: current_user }
      role_removal = described_class.call(args)

      expect(role_removal.success).to be false
      expect(role_removal.error_message).to eq "Super Admin roles cannot be removed."
    end
  end

  context "when current_user" do
    it "does not remove roles and raises an error", :aggregate_failures do
      role = current_user.roles.first
      resource_type = nil
      args = { user: current_user, role: role, resource_type: resource_type, admin: current_user }
      role_removal = described_class.call(args)

      expect(role_removal.success).to be false
      expect(role_removal.error_message).to eq "Admins cannot remove roles from themselves."
    end
  end

  it "removes roles from users", :aggregate_failures do
    user = create(:user, :trusted)
    role = user.roles.first
    resource_type = nil
    args = { user: user, role: role, resource_type: resource_type, admin: current_user }
    role_removal = described_class.call(args)

    expect(role_removal.success).to be true
    expect(role_removal.error_message).to be_nil
    expect(user.roles.count).to eq 1
  end

  it "removes :single_resource_admin roles from users", :aggregate_failures do
    user = create(:user, :single_resource_admin)
    role = user.roles.first
    resource_type = "Comment"
    args = { user: user, role: role, resource_type: resource_type, admin: current_user }
    role_removal = described_class.call(args)

    expect(role_removal.success).to be true
    expect(role_removal.error_message).to be_nil
    expect(user.roles.count).to eq 1
  end

  it "returns an error if there is an issue removing the role" do
    user = create(:user)
    allow(user).to receive(:remove_role).and_raise(StandardError)
    args = { user: user, role: nil, resource_type: nil, admin: current_user }
    role_removal = described_class.call(args)

    expect(role_removal.success).to be false
  end
end
