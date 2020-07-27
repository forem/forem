require "rails_helper"

RSpec.describe "Visiting collections", type: :system do
  let(:user) { create(:user) }
  let!(:collection1) { create(:collection, :with_articles, user: user) }
  let!(:collection2) { create(:collection, user: user) }

  before do
    sign_in user
    visit user_series_path(user.username)
  end

  it "shows all collections", :aggregate_failures do
    [collection1, collection2].each do |collection|
      expect(page.body).to have_link("#{collection.slug} (#{collection.articles.published.size} Part Series)")
    end
  end
end
