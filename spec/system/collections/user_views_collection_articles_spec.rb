require "rails_helper"

RSpec.describe "Viewing a collection" do
  let(:user) { create(:user) }
  let(:collection) { create(:collection, :with_articles, user: user) }

  before do
    sign_in user
    visit collection.path
  end

  it "shows all published articles" do
    collection.articles.published.each do |article|
      expect(page.body).to have_link(article.title)
    end
  end
end
