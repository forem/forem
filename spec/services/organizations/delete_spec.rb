require "rails_helper"

RSpec.describe Organizations::Delete, type: :service do
  let(:org) { create(:organization) }
  let(:org_id) { org.id }

  it "deletes an organization" do
    described_class.call(org)
    expect(Organization.find_by(id: org_id)).to be_nil
  end

  it "deletes notifications" do
    create_list(:notification, 5, organization_id: org_id)
    expect(Notification.where(organization_id: org_id).count).to eq(5)
    described_class.call(org)
    expect(Notification.where(organization_id: org_id).count).to eq(0)
  end

  context "with articles" do
    let!(:article) { create(:article, organization_id: org_id) }

    it "syncs articles" do
      expect(article.cached_organization.name).to eq(org.name)
      described_class.call(org)
      article.reload
      expect(article.cached_organization).to be_nil
    end

    it "removes the organization name from the .reading_list_document after destroy" do
      org.update(name: "ACME")
      expect(article.reload.reading_list_document).to include("acme")

      described_class.call(org)

      expect(article.reload.reading_list_document).not_to include("acme")
    end
  end
end
