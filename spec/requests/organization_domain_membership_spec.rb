require "rails_helper"

RSpec.describe "Organization domain membership" do
  let(:org_admin) { create(:user, :org_admin) }
  let(:organization) { org_admin.organizations.first }
  let(:domain) { create(:organization_email_domain, organization: organization, requested_by: org_admin) }

  before { allow(ForemInstance).to receive(:smtp_enabled?).and_return(true) }

  it "requires sign-in before an email challenge" do
    post organization_join_path(organization.slug), params: { work_email: "employee@foobar.com" }
    expect(response).to have_http_status(:redirect)
    expect(OrganizationMembershipChallenge.count).to eq(0)
  end

  it "accepts a domain request without allowing approval or enablement through parameters" do
    sign_in org_admin
    post organization_email_domains_path(organization.slug),
         params: { domain: "foobar.com", status: "approved", enabled: true }
    expect(organization.organization_email_domains.last.status).to eq("pending")
    expect(organization.organization_email_domains.last.enabled).to be(false)
  end

  it "does not let an ordinary member request a domain" do
    sign_in create(:user)
    expect do
      post organization_email_domains_path(organization.slug), params: { domain: "foobar.com" }
    end.to raise_error(Pundit::NotAuthorizedError)
  end

  it "does not enable a pending domain" do
    sign_in org_admin
    patch organization_email_domain_path(organization.slug, domain), params: { enabled: "true", status: "approved" }
    expect(domain.reload).not_to be_available
  end

  it "lets a superadmin approve and an org admin enable the domain" do
    sign_in create(:user, :super_admin)
    patch admin_organization_email_domain_path(domain), params: { decision: "approved" }
    expect(domain.reload.status).to eq("approved")
    expect(domain).not_to be_enabled
    sign_in org_admin
    patch organization_email_domain_path(organization.slug, domain), params: { enabled: "true" }
    expect(domain.reload).to be_available
  end

  it "does not let an ordinary site admin review domains" do
    sign_in create(:user, :admin)
    expect do
      patch admin_organization_email_domain_path(domain), params: { decision: "approved" }
    end.to raise_error(Pundit::NotAuthorizedError)
  end

  it "does not let an organization admin review domains" do
    sign_in org_admin
    expect do
      get admin_organization_email_domains_path
    end.to raise_error(Pundit::NotAuthorizedError)
  end

  it "scopes controls to the organization" do
    other_domain = create(:organization_email_domain)
    sign_in org_admin
    expect do
      delete organization_email_domain_path(organization.slug, other_domain)
    end.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "allows a rejected request to return to the approval queue" do
    domain.update!(status: "rejected")
    sign_in org_admin
    post organization_email_domains_path(organization.slug), params: { domain: "foobar.com", enabled: "true" }
    expect(domain.reload.status).to eq("pending")
    expect(domain).not_to be_enabled
    expect(organization.organization_email_domains.count).to eq(1)
  end

  it "records an exclusion when an org admin removes a member" do
    membership = create(:organization_membership, organization: organization)
    sign_in org_admin
    post "/users/remove_from_org", params: { user_id: membership.user_id, organization_id: organization.id }
    expect(OrganizationMembershipExclusion.exists?(user_id: membership.user_id, organization: organization)).to be(true)
    expect(OrganizationMembership.exists?(membership.id)).to be(false)
  end

  it "renders the review queue for superadmins" do
    domain
    sign_in create(:user, :super_admin)
    get admin_organization_email_domains_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("foobar.com", org_admin.username)
  end

  it "renders settings with domain status and no nested forms" do
    domain
    sign_in org_admin
    get organization_settings_path(organization.slug)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Pending approval", "section-email-domains")
    expect(Nokogiri::HTML.fragment(response.body).css("form form")).to be_empty
  end

  it "keeps the verification page private" do
    domain.update!(status: "approved", enabled: true)
    sign_in create(:user)
    get organization_join_path(organization.slug)
    expect(response).to have_http_status(:ok)
    expect(response.headers["Cache-Control"]).to include("private", "no-store")
    expect(response.body).to include("foobar.com", "Work email")
  end

  it "joins through the request and code forms" do
    domain.update!(status: "approved", enabled: true)
    user = create(:user)
    sign_in user
    allow(SecureRandom).to receive(:random_number).and_call_original
    allow(SecureRandom).to receive(:random_number).with(100_000_000).and_return(12_345_678)
    post organization_join_path(organization.slug), params: { work_email: "employee@foobar.com" }
    expect(response).to redirect_to(organization_join_path(organization.slug))
    follow_redirect!
    expect(response.body).to include("one-time-code")
    challenge = OrganizationMembershipChallenge.last
    patch organization_join_path(organization.slug), params: { challenge_id: challenge.id, otp: "12345678" }
    expect(organization.organization_memberships.find_by(user: user).type_of_user).to eq("member")
    follow_redirect!
    expect(response.body).to include("You are already a member")
  end

  it "invalidates codes when an org admin disables and re-enables membership" do
    domain.update!(status: "approved", enabled: true)
    user = create(:user)
    service = Organizations::DomainMembership.new(user: user, organization: organization)
    challenge = service.request_code("employee@foobar.com")
    sign_in org_admin
    patch organization_email_domain_path(organization.slug, domain), params: { enabled: "false" }
    patch organization_email_domain_path(organization.slug, domain), params: { enabled: "true" }
    expect(challenge.reload.expires_at).to be <= Time.current
  end
end
