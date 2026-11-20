require "rails_helper"

RSpec.describe "Admin visits badge achievements page" do
  let(:super_admin) { create(:user, :super_admin, :without_profile, profile_image: nil) }

  before do
    sign_in super_admin
    visit admin_badge_achievements_path
  end

  it "nests the content under Badges and highlights the Badges menu item in the sidebar", :aggregate_failures do
    expect(page).to have_css("h1.crayons-title", exact_text: "Badges")
    expect(page).to have_css('nav[aria-label="Admin"] [aria-current="page"]', exact_text: "Badges")
  end
end
