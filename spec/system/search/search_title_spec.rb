require "rails_helper"

RSpec.describe "Search page title" do
  let!(:current_user) { create(:user) }

  before do
    sign_in current_user
  end

  context "when search query param exists" do
    it "includes the search term in title and heading" do
      visit "/search?q=helloworld"

      expect(page).to have_title("Search Results for helloworld - #{ENV.fetch('COMMUNITY_NAME')}")
      expect(page.find("h1.crayons-title")).to have_content("Search results for helloworld")
    end
  end

  context "when search query param doesn't exist" do
    it "does not include search term in title and heading" do
      visit "/search"

      expect(page).to have_title("Search Results - #{ENV.fetch('COMMUNITY_NAME')}")
      expect(page.find("h1.crayons-title")).to have_content("Search results")
    end
  end
end
