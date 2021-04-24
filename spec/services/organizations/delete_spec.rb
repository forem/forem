require "rails_helper"

RSpec.describe Organizations::Delete, type: :service do
  let(:org) { create(:organization) }
  let(:org_id) { org.id }

  it "deletes an organization" do
    described_class.call(org)
    expect(Organization.find_by(id: org_id)).to be_nil
  end

  it "deletes notifications" do
    create_list(:notification, 5, organization_id: org.id)
    expect(Notification.where(organization_id: org_id).count).to eq(5)
    described_class.call(org)
    expect(Notification.where(organization_id: org_id).count).to eq(0)
  end
end
