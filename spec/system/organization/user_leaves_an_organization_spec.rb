require "rails_helper"

RSpec.describe "User leaves an organization" do
  let!(:org_user) { create(:user, :org_member) }
  let(:organization) { org_user.organizations.first }

  before do
    sign_in org_user
    visit "/settings/organization/#{organization.id}"
  end

  context "when user visits member organization settings" do
    it "shows the leave organization button", js: true do
      expect(page).to have_button("Leave Organization")
    end
  end

  context "when user leaves member organization" do
    it "leaves organization and shows confirmation" do
      click_button("Leave Organization")

      expect(page).to have_content("You have left your organization.")
    end
  end
end
