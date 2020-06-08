require "rails_helper"

RSpec.describe "Deleting Article", type: :system do
  let(:article) { create(:article) }

  before do
    sign_in article.user
    visit "/dashboard"
    click_on "MANAGE"
    click_on "DELETE"
  end

  # TODO: Uncomment this spec when we decide to use percy again
  xit "renders the page", js: true, percy: true do
    # Take snapshot before confirming deletion
    Percy.snapshot(page, name: "Article: confirm deletion")
  end

  it "author of article deletes own article", js: true do
    click_on "DELETE" # This is for confirming deletion
    expect(page).to have_text("Write your first post now")
  end
end
