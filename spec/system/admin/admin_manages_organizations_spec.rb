require "rails_helper"

RSpec.describe "Admin manages organizations" do
  let(:admin) { create(:user, :super_admin) }
  let(:organization) { create(:organization) }

  before { sign_in admin }

  context "when searching for organizations" do
    it "searches for organizations" do
      create_list(:organization, 5)
      visit admin_organizations_path

      fill_in "Search", with: organization.name.to_s, match: :first
      click_on "Search"

      expect(page.body).to have_link(organization.name)
    end
  end

  context "when managing credits for a single organization" do
    before { visit admin_organization_path(organization) }

    it "does not show the remove form when there are no credits" do
      expect(page).to have_button("Add Org Credits")
      expect(page).to have_no_button("Remove Org Credits")
    end
  end

  context "when bulk adding users to an organization" do
    let!(:user1) { create(:user, username: "sys_alice") }
    let!(:user2) { create(:user, username: "sys_bob") }

    before { visit admin_organization_path(organization) }

    it "adds users to the organization from the admin page", :aggregate_failures do
      fill_in "Usernames", with: "@#{user1.username}, #{user2.username}"
      select "Member", from: "Role"
      click_on "Bulk Add Members"

      expect(page).to have_content(user1.username)
      expect(page).to have_content(user2.username)
      expect(organization.reload.organization_memberships.pluck(:user_id)).to contain_exactly(user1.id, user2.id)
    end
  end
end
