require "rails_helper"

RSpec.describe "Collections" do
  let(:user) { create(:user) }
  let(:collection) { create(:collection, :with_articles, user: user) }

  describe "GET user collections index" do
    it "returns 200" do
      get "/#{user.username}/series"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET user collection show" do
    it "returns 200" do
      get collection.path
      expect(response).to have_http_status(:ok)
    end

    it "redirects legacy series IDs to canonical collection path" do
      replacement_collection = create(:collection, user: user, slug: "replacement-series")
      CollectionIdAlias.create!(legacy_collection_id: 999_999_999, collection: replacement_collection)

      get "/#{user.username}/series/999999999"

      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to(replacement_collection.path)
    end

    it "returns not found when series ID is unknown and has no alias" do
      expect do
        get "/#{user.username}/series/999999998"
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "GET large user collection show" do
    it "returns the proper article count and text for a large collection", :aggregate_failures do
      amount = 6
      large_collection = create(:collection, :with_articles, amount: amount, user: user)

      get "/#{user.username}/#{large_collection.articles.first.slug}"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include "#{amount - 4} more parts..."
    end
  end
end
