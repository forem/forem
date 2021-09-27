require "rails_helper"

RSpec.describe "Admin manages organizations", type: :system do
  let(:admin) { create(:user, :super_admin) }
  let(:organization) { create(:organization) }

  before { sign_in admin }

  context "when searching for organizations" do
    it "searches for organizations" do
      create_list :organization, 5
      visit admin_organizations_path

      fill_in "search", with: organization.name.to_s
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
end
