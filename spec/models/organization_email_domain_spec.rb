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

  it "opens membership immediately on superadmin approval" do
    domain = create(:organization_email_domain)
    expect(domain).not_to be_available
    domain.review!(create(:user, :super_admin), "approved")
    expect(domain).to be_available
    expect(domain.reviewed_at).to be_present
    expect(Note.where(noteable: domain.organization).last.content).to include("foobar.com: approved")
  end

  it "preserves an org admin's pause when approval is repeated" do
    domain = create(:organization_email_domain, status: "approved", enabled: false)
    domain.review!(create(:user, :super_admin), "approved")
    expect(domain.reload).not_to be_available
  end

  it "closes membership and expires outstanding codes on rejection or revocation" do
    reviewer = create(:user, :super_admin)
    %w[rejected revoked].each do |decision|
      domain = create(:organization_email_domain, :available)
      challenge = domain.organization_membership_challenges.create!(
        user: create(:user), email: "employee@foobar.com", otp_digest: "digest", expires_at: 10.minutes.from_now,
      )
      domain.review!(reviewer, decision)
      expect(domain.reload).not_to be_enabled
      expect(challenge.reload.expires_at).to be <= Time.current
    end
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
