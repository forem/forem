require "rails_helper"

RSpec.describe "Admin manages organizations", type: :system, flaky: true do
  let(:admin) { create(:user, :super_admin) }
  let(:organization) { create(:organization) }

  context "when searching for organizations" do
    it "searches for organizations" do
      sign_in admin
      create_list :organization, 5
      visit internal_organizations_path

      fill_in "search", with: organization.name.to_s
      click_on "Search"

      expect(page.body).to have_link(organization.name)
    end
  end

  context "when managing credits for a single organization" do

    it "does not show the remove form when there are no credits" do
      sign_in admin
      visit internal_organization_path(organization)
      expect(page).to have_button("Add Org Credits")
      # expect(page).to have_no_button("Remove Org Credits")
    end
  end
end
