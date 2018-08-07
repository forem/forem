require "rails_helper"

RSpec.describe "Deleting Article", js: true do
  let(:author) { create(:user) }
  let(:article) { create(:article, user_id: author.id) }

  def delete_article_via_dashboard
    visit "/dashboard"
    delete_link = find_link("DELETE")
    delete_link.click
    second_link = find_link("DELETE")
    second_link.click
  end

  before do
    article
  end

  it "author of article deletes own article" do
    sign_in author
    delete_article_via_dashboard
    expect(page).to have_text("Write your first post now")
  end
end
