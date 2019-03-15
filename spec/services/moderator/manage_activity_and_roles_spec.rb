require "rails_helper"

RSpec.describe Moderator::ManageActivityAndRoles, type: :service do
  let(:user) { create(:user) }
  let(:admin) { create(:user, :super_admin) }

  def update_user_role
    described_class.handle_user_roles(
      admin: admin,
      user: user,
      user_params: { note_for_current_role: "warning user", user_status: "Warn" },
    )
  end

  before do
    user.add_role :banned
  end

  it "updates user status" do
    update_user_role
    expect(user.warned).to be true
    expect(user.banned).to be false
  end
end
