require "rails_helper"

RSpec.describe "Admin visits badge achievements page" do
  let(:super_admin) { create(:user, :super_admin) }

  before do
    sign_in super_admin
    visit admin_badge_achievements_path
  end

  it "nests the content under Badges" do
    expect(find("h1.crayons-title").text).to eq("Badges")
  end

  it "highlights the Badges menu item in the sidebar" do
    within('nav[aria-label="Admin"]') do
      expect(find("[aria-current='page']").text).to eq("Badges")
    end
  end
end
