require "rails_helper"

RSpec.describe OrganizationEmailDomain do
  it "normalizes exact domains" do
    domain = create(:organization_email_domain, domain: "  FooBar.COM ")
    expect(domain.domain).to eq("foobar.com")
  end

  it "rejects public providers and invalid domain syntax" do
    %w[gmail.com https://foobar.com @foobar.com *.foobar.com foobar.com/path localhost -foo.com foo..com].each do |name|
      expect(build(:organization_email_domain, domain: name)).not_to be_valid
    end
  end

  it "requires a new request for a different domain" do
    domain = create(:organization_email_domain, :available)
    expect(domain.update(domain: "other.com")).to be(false)
  end

  it "requires approval and explicit enablement" do
    domain = create(:organization_email_domain)
    expect(domain).not_to be_available
    domain.review!(create(:user, :super_admin), "approved")
    expect(domain).not_to be_available
    expect(domain.reviewed_at).to be_present
    expect(Note.where(noteable: domain.organization).last.content).to include("foobar.com: approved")
    domain.update!(enabled: true)
    expect(domain).to be_available
  end

  it "retains the request when the requester deletes their account" do
    domain = create(:organization_email_domain)
    domain.requested_by.destroy!
    expect(domain.reload.requested_by).to be_nil
  end

  it "rejects approval by an ordinary site admin" do
    domain = create(:organization_email_domain)
    expect { domain.review!(create(:user, :admin), "approved") }.to raise_error(Pundit::NotAuthorizedError)
    expect(domain.reload.status).to eq("pending")
  end
end
