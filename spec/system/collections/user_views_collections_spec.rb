require "rails_helper"

RSpec.describe "Visiting collections" do
  let(:user) { create(:user) }
  let!(:collection1_with_articles) { create(:collection, :with_articles, user: user) }
  let!(:collection2_with_articles) { create(:collection, :with_articles, user: user) }

  let!(:collection1_without_articles) { create(:collection, user: user) }
  let!(:collection2_without_articles) { create(:collection, user: user) }

  before do
    sign_in user
    visit user_series_path(user.username)
  end

  it "shows all collections with articles", :aggregate_failures do
    [collection1_with_articles, collection2_with_articles].each do |collection|
      expect(page.body).to have_link("#{collection.slug} (#{collection.articles.published.size} Part Series)")
    end
  end

  it "does not show collections without articles", :aggregate_failures do
    [collection1_without_articles, collection2_without_articles].each do |collection|
      expect(page.body).not_to have_link("#{collection.slug} (#{collection.articles.published.size} Part Series)")
    end
  end
end
