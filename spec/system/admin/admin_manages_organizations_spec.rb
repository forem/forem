require "rails_helper"

RSpec.describe "Admin manages organizations" do
  let(:admin) { create(:user, :super_admin, :without_profile, profile_image: nil) }
  let(:organization) { create(:organization) }

  before { sign_in admin }

  context "when searching for organizations" do
    it "searches for organizations", :aggregate_failures do
      other_organization = create(:organization)
      visit admin_organizations_path

      fill_in "search", with: organization.name.to_s
      click_on "Search"

      expect(page.body).to have_link(organization.name)
      expect(page.body).to have_no_link(other_organization.name)
    end
  end

  context "when viewing and bulk adding users to an organization" do
    let!(:user1) { create(:user, :without_profile, profile_image: nil, username: "sys_alice") }
    let!(:user2) { create(:user, :without_profile, profile_image: nil, username: "sys_bob") }

    before { visit admin_organization_path(organization) }

    it "hides remove credits when none exist and bulk adds members", :aggregate_failures do
      expect(page).to have_button("Add Org Credits")
      expect(page).to have_no_button("Remove Org Credits")

      fill_in "Usernames", with: "@#{user1.username}, #{user2.username}"
      select "Member", from: "Role"
      click_on "Bulk Add Members"

      expect(page).to have_content(user1.username)
      expect(page).to have_content(user2.username)
      expect(organization.reload.organization_memberships.pluck(:user_id)).to contain_exactly(user1.id, user2.id)
    end
  end
end
