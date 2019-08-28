require "rails_helper"

RSpec.describe "Deleting Article", type: :system do
  let(:article) { create(:article) }

  it "author of article deletes own article" do
    sign_in article.user
    visit "/dashboard"
    click_on "MANAGE"
    click_on "DELETE"
    click_on "DELETE" # This is for confirming deletion
    expect(page).to have_text("Write your first post now")
  end
end
