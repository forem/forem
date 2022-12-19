require "rails_helper"

RSpec.describe "Organization setting page(/settings/organization)", type: :system, js: true do
  def fill_in_org_form
    fill_in "organization[name]", with: "Organization Name"
    fill_in "organization[slug]", with: "Organization"
    attach_file(
      "organization_profile_image",
      Rails.root.join("app/assets/images/android-icon-36x36.png"),
    )
    fill_in "organization[bg_color_hex]", with: "#000000"
    fill_in "organization[text_color_hex]", with: "#ffffff"
    fill_in "organization[url]", with: "http://company.com"
    fill_in "organization[summary]", with: "Summary"
    fill_in "organization[proof]", with: "Proof"
  end

  let(:user) { create(:user) }
  let(:user2) { create(:user, username: "newuser") }
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
    click_button "Create Organization"

    expect(page).to have_text("Your organization was successfully created and you are an admin.")
  end

  it "promotes a member to an admin" do
    join_org(user, organization, :admin)
    join_org(user2, organization, :member)

    visit "settings/organization"
    click_button("Make admin")

    expect(page).to have_text("#{user2.name} is now an admin.")
  end

  it "revokes an admin's privileges" do
    join_org(user, organization, :admin)
    join_org(user2, organization, :admin)

    visit "settings/organization"
    click_button("Revoke admin status")
    expect(page).to have_text("#{user2.name} is no longer an admin.")
  end

  it "remove user from organization" do
    join_org(user, organization, :admin)
    join_org(user2, organization, :member)

    visit "settings/organization"
    click_button("Remove from org")
    expect(page).to have_text("#{user2.name} is no longer part of your organization.")
  end

  it "uses the update page when an update error occurs" do
    join_org(user, organization, :admin)

    visit "/settings/organization"
    fill_in "organization[name]", with: user.name
    click_button("Save")
    expect(page).to have_text("Organization details")
  end
end
