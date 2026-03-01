require "rails_helper"

RSpec.describe "RssFeedImports" do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe "GET /rss_feed_imports" do
    it "renders the import dashboard" do
      feed = create(:rss_feed, user: user)
      create(:rss_feed_item, rss_feed: feed, status: :imported)
      create(:rss_feed_item, rss_feed: feed, status: :error, error_message: "Parse error")
      create(:rss_feed_item, rss_feed: feed, status: :pending)

      get rss_feed_imports_path

      expect(response).to have_http_status(:ok)
    end

    it "shows empty state when user has no feeds" do
      get rss_feed_imports_path

      expect(response).to have_http_status(:ok)
    end

    it "only shows feeds belonging to current user" do
      create(:rss_feed, user: user, name: "My Feed")
      create(:rss_feed, user: create(:user), name: "Other Feed")

      get rss_feed_imports_path

      expect(response.body).to include("My Feed")
      expect(response.body).not_to include("Other Feed")
    end
  end
end
