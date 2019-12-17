require "rails_helper"

RSpec.describe "Admin manages organizations", type: :system do
  let(:admin) { create(:user, :super_admin) }
  let(:organization) { create(:organization) }

  before do
    create_list :organization, 5
    sign_in admin
    visit "/internal/organizations"
  end

  it "searches for organizations" do
    fill_in "search", with: organization.name.to_s
    click_on "Search"
    expect(page.body).to have_link(organization.name)
  end
end
