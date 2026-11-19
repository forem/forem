require "rails_helper"

RSpec.describe "BottomItems" do
  describe "GET /bottom_items" do
    it "sets article, author identity, and organization Surrogate-Key headers", :aggregate_failures do
      organization = create(:organization)
      article = create(:article, organization: organization, published: true)

      get "/bottom_items", params: { article_id: article.id }

      expect(response).to have_http_status(:ok)
      expect(response.headers["Surrogate-Key"].split).to include(
        article.record_key,
        *article.user.profile_identity_cache_keys,
        organization.record_key,
      )
    end

    it "tags unpublished or missing article lookups with the article surrogate key" do
      draft = create(:article, published: false)

      get "/bottom_items", params: { article_id: draft.id }

      expect(response).to have_http_status(:ok)
      expect(response.headers["Surrogate-Key"]).to include(draft.record_key)
    end
  end
end
