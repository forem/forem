require "rails_helper"

RSpec.describe "Admin bans user", type: :system do
  let(:admin)  { create(:user, :super_admin) }

  before do
    sign_in admin
    visit "/internal/badges"
  end

  it "views the page" do
    expect(page).to have_content("Badges")
  end
end
