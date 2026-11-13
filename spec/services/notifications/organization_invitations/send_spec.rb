require "rails_helper"

RSpec.describe Notifications::OrganizationInvitations::Send, type: :service do
  let(:inviter) { create(:user) }
  let(:invitee) { create(:user) }
  let(:organization) { create(:organization) }
  let(:membership) do
    create(:organization_membership, user: invitee, organization: organization, type_of_user: "pending")
  end

  it "notifies the invitee", :aggregate_failures do
    notification = described_class.call(membership, inviter: inviter)

    expect(notification.user_id).to eq(invitee.id)
    expect(notification.notifiable).to eq(membership)
    expect(notification.action).to eq("Invited")
  end

  it "includes the organization, the inviter and the pending status", :aggregate_failures do
    json_data = described_class.call(membership, inviter: inviter).json_data

    expect(json_data.dig("organization", "id")).to eq(organization.id)
    expect(json_data.dig("user", "id")).to eq(inviter.id)
    expect(json_data.dig("organization_invitation", "id")).to eq(membership.id)
    expect(json_data.dig("organization_invitation", "status")).to eq("pending")
  end

  it "belongs to the organization so deleting the organization cleans it up" do
    notification = described_class.call(membership)

    expect(notification.organization_id).to eq(organization.id)
  end

  it "does not notify once the invitation was accepted" do
    membership.confirm!

    expect { described_class.call(membership) }.not_to change(Notification, :count)
  end

  it "does not notify once the invitation was withdrawn" do
    stale_membership = OrganizationMembership.find(membership.id)
    membership.destroy

    expect { described_class.call(stale_membership) }.not_to change(Notification, :count)
  end

  it "works without a known inviter" do
    json_data = described_class.call(membership).json_data

    expect(json_data).not_to have_key("user")
  end

  it "does not notify twice" do
    described_class.call(membership)

    expect { described_class.call(membership) }.not_to change(Notification, :count)
  end
end
