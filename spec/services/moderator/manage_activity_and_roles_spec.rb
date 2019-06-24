require "rails_helper"

RSpec.describe Moderator::ManageActivityAndRoles, type: :service do
  let(:user) { create(:user) }
  let(:admin) { create(:user, :super_admin) }

  it "updates user status" do
    user.add_role :banned
    user.reload
    described_class.handle_user_roles(
      admin: admin,
      user: user,
      user_params: { note_for_current_role: "warning user", user_status: "Warn" },
    )
    expect(user.warned).to be true
    expect(user.banned).to be false
  end

  it "updates negative role to positive role" do
    user.add_role :comment_banned
    described_class.handle_user_roles(
      admin: admin,
      user: user,
      user_params: { note_for_current_role: "user in good standing", user_status: "Regular Member" },
    )
    expect(user.banned).to be false
    expect(user.roles.count).to eq(0)
  end
end
