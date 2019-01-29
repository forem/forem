require "rails_helper"

RSpec.describe "Deleting Article", js: true, type: :feature do
  let(:article) { create(:article) }

  before do
    # Notification.send_to_followers(article, "Published")
  end

  it "author of article deletes own article", driver: :chrome do
    sign_in article.user
    visit "/dashboard"
    click_on "DELETE"
    click_on "DELETE"
    expect(page).to have_text("Write your first post now")
  end
end
