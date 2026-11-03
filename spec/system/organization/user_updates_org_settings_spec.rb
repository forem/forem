require "rails_helper"

RSpec.describe "Organization setting page(/settings/organization)" do
  def fill_in_org_form
    fill_in "organization[name]", with: "Organization Name"
    fill_in "organization[slug]", with: "Organization"
    attach_file(
      "organization_profile_image",
      Rails.root.join("app/assets/images/android-icon-36x36.png"),
    )
    fill_in "organization[url]", with: "http://company.com"
    fill_in "organization[summary]", with: "Summary"
    fill_in "organization[proof]", with: "Proof"
  end

  let(:user) { create(:user, :without_profile, profile_image: nil) }
  let(:user2) { create(:user, :without_profile, profile_image: nil, username: "newuser") }
  let(:organization) { create(:organization) }

  before do
    sign_in user
  end

  def join_org(user, organization, type_of_user)
    create(
      :organization_membership,
      user: user,
      organization: organization,
      type_of_user: type_of_user,
    )
  end

  it "user creates an organization" do
    visit "/settings/organization"
    fill_in_org_form
    click_on "Create Organization"

    expect(page).to have_text("Your organization was successfully created and you are an admin.")
  end

  it "promotes, revokes, and removes a member and renders the update page on error", :aggregate_failures do
    join_org(user, organization, :admin)
    join_org(user2, organization, :member)

    visit "/#{organization.slug}/settings"
    click_on("Make admin")
    expect(page).to have_text("#{user2.name} is now an admin.")

    click_on("Revoke admin status")
    expect(page).to have_text("#{user2.name} is no longer an admin.")

    click_on("Remove from org")
    expect(page).to have_text("#{user2.name} is no longer part of your organization.")

    fill_in "organization[name]", with: ""
    click_on("Save page")
    expect(page).to have_text("Organization details")
  end
end
