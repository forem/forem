require "rails_helper"

RSpec.describe "Search page title" do
  it "includes the search term in title and heading when present and omits it when absent", :aggregate_failures do
    visit "/search?q=helloworld"

    expect(page).to have_title("Search Results for helloworld - DEV(local)")
    expect(page.find("h1.crayons-title")).to have_content("Search results for helloworld")

    visit "/search"

    expect(page).to have_title("Search Results - DEV(local)")
    expect(page.find("h1.crayons-title")).to have_content("Search results")
  end
end
