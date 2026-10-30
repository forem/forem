require "rails_helper"

RSpec.describe "Admin visits extentions page" do
  let(:super_admin) { create(:user, :super_admin, :without_profile, profile_image: nil) }

  before do
    sign_in super_admin
    visit admin_extensions_path
  end

  it "nests the content under Developer Tools and highlights the sidebar menu item", :aggregate_failures do
    expect(page).to have_css("h1.crayons-title", exact_text: "Developer Tools")
    expect(page).to have_css('nav[aria-label="Admin"] [aria-current="page"]', exact_text: "Developer Tools")
  end
end
