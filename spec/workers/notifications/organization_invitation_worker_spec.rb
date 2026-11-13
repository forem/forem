require "rails_helper"

RSpec.describe Notifications::OrganizationInvitationWorker, type: :worker do
  subject(:worker) { described_class.new }

  before { allow(Notifications::OrganizationInvitations::Send).to receive(:call) }

  it "notifies the invitee of a pending invitation" do
    membership = create(:organization_membership, type_of_user: "pending")
    inviter = create(:user)

    worker.perform(membership.id, inviter.id)

    expect(Notifications::OrganizationInvitations::Send).to have_received(:call).with(membership, inviter: inviter)
  end

  it "skips invitations that were already answered" do
    membership = create(:organization_membership, type_of_user: "member")

    worker.perform(membership.id)

    expect(Notifications::OrganizationInvitations::Send).not_to have_received(:call)
  end

  it "skips invitations that were withdrawn" do
    worker.perform(-1)

    expect(Notifications::OrganizationInvitations::Send).not_to have_received(:call)
  end
end
