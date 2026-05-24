require "rails_helper"

RSpec.describe "StoriesPerformanceFix", type: :request do
  let(:user) { create(:user) }

  describe "GET /:username/:slug (article show with collection)" do
    let(:collection) { create(:collection, user: user) }
    let(:article) do
      create(:article, user: user, published: true, collection: collection,
             cached_tag_list: "ruby, rails", main_image: "https://example.com/image.png")
    end
    let!(:other_collection_articles) do
      create_list(:article, 3, user: user, published: true, collection: collection,
                  cached_tag_list: "ruby", main_image: "https://example.com/other.png")
    end

    before do
      # Create articles to trigger sticky nav suggestions
      create_list(:article, 3, user: user, published: true, cached_tag_list: "ruby")
      career_articles = create_list(:article, 3, published: true, cached_tag_list: "career",
                                    public_reactions_count: 50)
      career_articles.each { |a| a.update_columns(published_at: 1.day.ago) }
    end

    it "renders the article show page with collection without MissingAttributeError" do
      # The collection partial uses: id, path, title, slug, published_at, crossposted_at,
      # user_id, organization_id, cached_tag_list, subforem_id, main_image
      get article.path
      follow_redirect! if response.status == 301
      expect(response).to have_http_status(:ok)
    end

    it "renders sticky nav with user stickies (GetUserStickies)" do
      # GetUserStickies uses: id, path, title, cached_tag_list, organization_id, user_id, subforem_id
      get article.path
      follow_redirect! if response.status == 301
      expect(response).to have_http_status(:ok)
    end

    it "renders sticky nav with trending articles (SuggestStickies) when no user stickies" do
      # Remove all same-author articles so GetUserStickies returns empty
      user.articles.where.not(id: article.id).destroy_all
      # SuggestStickies uses: id, path, title, cached_tag_list, cached_user, organization_id, user_id
      get article.path
      follow_redirect! if response.status == 301
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /:username (user profile with articles)" do
    let!(:articles) do
      create_list(:article, 3, user: user, published: true, cached_tag_list: "ruby",
                  main_image: "https://example.com/image.png")
    end

    it "renders user profile page without MissingAttributeError" do
      # limited_column_select provides: path, title, id, published, comments_count,
      # public_reactions_count, cached_tag_list, main_image, main_image_background_hex_color,
      # updated_at, slug, video, user_id, organization_id, video_source_url, video_code,
      # video_thumbnail_url, video_closed_caption_track_url, cached_user, cached_organization,
      # published_at, crossposted_at, description, reading_time, video_duration_in_seconds,
      # score, last_comment_at, main_image_height, type_of, edited_at, processed_html, subforem_id
      get "/#{user.username}"
      expect(response).to have_http_status(:ok)
    end

    it "renders all article titles on the profile page" do
      get "/#{user.username}"
      expect(response).to have_http_status(:ok)
      articles.each do |a|
        expect(response.body).to include(a.title)
      end
    end

    it "renders article reading time without MissingAttributeError" do
      get "/#{user.username}"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("min read")
    end

    context "with pinned articles" do
      let!(:pin) { create(:profile_pin, profile: user, pinnable: articles.first) }

      it "renders pinned articles without MissingAttributeError" do
        get "/#{user.username}"
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Pinned")
        expect(response.body).to include(articles.first.title)
      end
    end
  end

  describe "GET /:org_slug (organization profile with articles)" do
    let(:org) { create(:organization) }
    let!(:org_membership) { create(:organization_membership, user: user, organization: org) }
    let!(:org_articles) do
      create_list(:article, 3, organization: org, user: user, published: true,
                  cached_tag_list: "devops", main_image: "https://example.com/org.png")
    end

    it "renders organization profile page without MissingAttributeError" do
      get "/#{org.slug}"
      expect(response).to have_http_status(:ok)
    end

    it "renders org article cards with all required columns" do
      get "/#{org.slug}"
      expect(response).to have_http_status(:ok)
      org_articles.each do |a|
        expect(response.body).to include(a.title)
      end
    end
  end
end
