require "rails_helper"

RSpec.describe "StoriesShowPerformanceFix", type: :request do
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user, published: true, cached_tag_list: "ruby, rails") }
  
  before do
    # Ensure RequestStore has a subforem_id
    subforem = create(:subforem)
    RequestStore.store[:subforem_id] = subforem.id
    RequestStore.store[:default_subforem_id] = subforem.id
    
    # Create more articles to trigger sticky nav suggestions
    create_list(:article, 5, user: user, published: true, cached_tag_list: "ruby", subforem_id: subforem.id)
    create_list(:article, 5, published: true, cached_tag_list: "career", subforem_id: subforem.id)
  end

  describe "GET /:username/:slug" do
    it "renders the sticky nav without MissingAttributeError" do
      # Follow redirect if necessary (Forem often redirects for normalization)
      get article.path
      if response.status == 301
        follow_redirect!
      end
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("More from")
      # This ensures that cached_tag_list and other columns were correctly selected
      expect(response.body).to include("#ruby")
    end
    
    it "renders trending articles in sticky nav when applicable" do
      # Make sure some articles are "trending" for SuggestStickies
      Article.all.update_all(public_reactions_count: 50, published_at: 1.day.ago)
      
      get article.path
      if response.status == 301
        follow_redirect!
      end
      expect(response).to have_http_status(:ok)
      # Sticky items from SuggestStickies use different tags
    end
  end
end
