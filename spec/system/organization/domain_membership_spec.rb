require "rails_helper"

RSpec.describe "Organization membership through a work email", :js do
  let(:organization) { create(:organization, name: "Foobar", slug: "foobar") }
  let!(:domain) { create(:organization_email_domain, :available, organization: organization) }

  before do
    allow(ForemInstance).to receive(:smtp_enabled?).and_return(true)
    allow(SecureRandom).to receive(:random_number).and_call_original
    allow(SecureRandom).to receive(:random_number).with(100_000_000).and_return(12_345_678)
  end

  it "verifies and joins from the desktop and mobile forms" do
    user = create(:user)
    sign_in user
    visit organization.path
    expect(page).to have_link("Work at Foobar? Join the organization", href: organization_join_path(organization.slug))
    click_on "Work at Foobar? Join the organization"
    expect(page).to have_content("permission to publish")
    page.driver.resize(1280, 900)
    fill_in "Work email", with: "employee@foobar.com"
    click_on "Send verification code"
    expect(page).to have_content("Check your work email")
    page.driver.resize(390, 844)
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
    expect(page).to have_css("details.org-join__resend:not([open])")
    find("summary", text: "Need another code or a different email?").click
    expect(page).to have_field("Work email", with: "employee@foobar.com")
    fill_in "Eight-digit verification code", with: "12345678"
    click_on "Verify and join"
    expect(page).to have_content("You are already a member")
    expect(organization.organization_memberships.find_by(user: user).type_of_user).to eq("member")
  end

  it "shows domain controls in organization settings" do
    admin = create(:user)
    create(:organization_membership, user: admin, organization: organization, type_of_user: "admin")
    sign_in admin
    visit organization_settings_path(organization.slug)
    within("#section-email-domains") do
      expect(page).to have_content("foobar.com")
      expect(page).to have_content("Approved")
      expect(page).to have_button("Disable membership")
    end
    page.driver.resize(1280, 900)
    page.scroll_to(find_by_id("section-email-domains"), align: :top)
    within("#section-email-domains") { click_on "Disable membership" }
    expect(domain.reload).not_to be_enabled
  end

  it "shows the domain review queue to a superadmin" do
    domain.update!(status: "pending", enabled: false)
    sign_in create(:user, :super_admin)
    visit admin_organization_email_domains_path
    expect(page).to have_content("Organization email domain requests")
    expect(page).to have_content("Pending approval")
    page.driver.resize(1280, 900)
    click_on "Approve"
    expect(page).to have_content("Domain review saved")
    expect(domain.reload).to have_attributes(status: "approved", enabled: true)
    visit organization.path
    expect(page).to have_link("Work at Foobar? Join the organization")
    org_admin = create(:user)
    create(:organization_membership, user: org_admin, organization: organization, type_of_user: "admin")
    sign_in org_admin
    visit organization_settings_path(organization.slug)
    within("#section-email-domains") { expect(page).to have_button("Disable membership") }
  end
end
