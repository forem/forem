require "rails_helper"

RSpec.describe Notifications::OrganizationInvitations::Update, type: :service do
  let(:inviter) { create(:user) }
  let(:membership) { create(:organization_membership, type_of_user: "pending") }
  let!(:notification) { Notifications::OrganizationInvitations::Send.call(membership, inviter: inviter) }

  it "marks the invitee's notification as accepted and read, keeping the inviter", :aggregate_failures do
    membership.update!(type_of_user: "member")

    described_class.call(membership)
    notification.reload

    expect(notification.read).to be(true)
    expect(notification.json_data.dig("organization_invitation", "status")).to eq("accepted")
    expect(notification.json_data.dig("user", "id")).to eq(inviter.id)
  end
end
