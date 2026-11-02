require "rails_helper"

RSpec.describe Notifications::CoAuthorInvitationWorker, type: :worker do
  subject(:worker) { described_class.new }

  before { allow(Notifications::CoAuthorInvitations::Send).to receive(:call) }

  it "notifies the invitee of a pending invitation" do
    invitation = create(:co_author_invitation)

    worker.perform(invitation.id)

    expect(Notifications::CoAuthorInvitations::Send).to have_received(:call).with(invitation)
  end

  it "skips invitations that were already answered" do
    invitation = create(:co_author_invitation, :declined)

    worker.perform(invitation.id)

    expect(Notifications::CoAuthorInvitations::Send).not_to have_received(:call)
  end

  it "skips invitations that were withdrawn" do
    worker.perform(-1)

    expect(Notifications::CoAuthorInvitations::Send).not_to have_received(:call)
  end
end
