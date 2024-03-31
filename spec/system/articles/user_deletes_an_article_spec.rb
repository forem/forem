require "rails_helper"

RSpec.describe "Deleting Article" do
  let(:article) { create(:article) }

  before do
    sign_in article.user
    visit "/dashboard"
    click_on "Manage"
    click_on "Delete"
  end

  it "author of article deletes own article", js: true do
    click_on "Delete" # This is for confirming deletion
    expect(page).to have_text("Write your first post now")
  end
end
