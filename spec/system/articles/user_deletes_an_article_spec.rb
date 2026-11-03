require "rails_helper"

RSpec.describe "Deleting Article" do
  let(:article) { create(:article, with_tags: false) }

  before do
    sign_in article.user
    visit "/dashboard"
    click_on "Manage"
  end

  it "author of article deletes own article" do
    within "#section-delete" do
      click_on "Delete Post"
    end
    click_on "Delete" # This is for confirming deletion
    expect(page).to have_text("Write your first post now")
  end
end
