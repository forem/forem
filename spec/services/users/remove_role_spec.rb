require "rails_helper"

RSpec.describe Users::RemoveRole, type: :service do
  let(:current_user) { create(:user, :admin) }

  it "removes roles from users", :aggregate_failures do
    user = create(:user, :trusted)
    role = user.roles.first
    resource_type = nil
    args = { user: user, role: role, resource_type: resource_type }
    role_removal = described_class.call(**args)

    expect(role_removal.success).to be true
    expect(role_removal.error_message).to be_nil
    expect(user.roles.count).to eq 1
  end

  it "removes :single_resource_admin roles from users", :aggregate_failures do
    user = create(:user, :single_resource_admin)
    role = user.roles.first
    resource_type = "Comment"
    args = { user: user, role: role, resource_type: resource_type }
    role_removal = described_class.call(**args)

    expect(role_removal.success).to be true
    expect(role_removal.error_message).to be_nil
    expect(user.roles.count).to eq 1
  end

  it "returns an error if there is an issue removing the role" do
    user = create(:user)
    allow(user).to receive(:remove_role).and_raise(StandardError)
    args = { user: user, role: nil, resource_type: nil }
    role_removal = described_class.call(**args)

    expect(role_removal.success).to be false
  end
end
