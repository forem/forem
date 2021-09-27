require "rails_helper"

RSpec.describe "Collections", type: :request do
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
