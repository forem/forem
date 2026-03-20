require "rails_helper"

RSpec.describe Notifications::OrganizationDeverification::Send, type: :service do
  let(:organization) { create(:organization) }
  let(:admin_user) { create(:user) }
  let(:member_user) { create(:user) }

  before do
    create(:organization_membership, organization: organization, user: admin_user, type_of_user: "admin")
    create(:organization_membership, organization: organization, user: member_user, type_of_user: "member")
  end

  it "creates an org-level notification and user-level notifications for admins" do
    expect do
      described_class.call(organization)
    end.to change(Notification, :count).by(2) # 1 org + 1 admin
  end

  it "creates an org-level notification with correct attributes" do
    described_class.call(organization)
    notification = Notification.find_by(organization_id: organization.id, user_id: nil)

    expect(notification).to be_present
    expect(notification.notifiable).to eq(organization)
    expect(notification.action).to start_with("Deverification::")
  end

  it "creates user-level notifications for admin members" do
    described_class.call(organization)
    notification = Notification.find_by(user_id: admin_user.id)

    expect(notification).to be_present
    expect(notification.notifiable).to eq(organization)
    expect(notification.action).to start_with("Deverification::")
  end

  it "does not create user-level notifications for non-admin members" do
    described_class.call(organization)
    expect(Notification.find_by(user_id: member_user.id)).to be_nil
  end

  it "includes organization data in json_data" do
    described_class.call(organization)
    notification = Notification.find_by(organization_id: organization.id, user_id: nil)

    expect(notification.json_data["organization"]["id"]).to eq(organization.id)
    expect(notification.json_data["organization"]["name"]).to eq(organization.name)
    expect(notification.json_data["organization"]["slug"]).to eq(organization.slug)
  end

  it "creates notifications for multiple admins" do
    second_admin = create(:user)
    create(:organization_membership, organization: organization, user: second_admin, type_of_user: "admin")

    expect do
      described_class.call(organization)
    end.to change(Notification, :count).by(3) # 1 org + 2 admins
  end
end
