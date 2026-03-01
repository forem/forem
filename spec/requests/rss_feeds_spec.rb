require "rails_helper"

RSpec.describe "RssFeeds" do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe "POST /rss_feeds" do
    it "creates a new rss feed" do
      allow(Feeds::ValidateUrl).to receive(:call).and_return(true)

      expect do
        post rss_feeds_path, params: {
          rss_feed: { feed_url: "https://example.com/feed.xml", name: "My Blog" }
        }
      end.to change(RssFeed, :count).by(1)

      feed = RssFeed.last
      expect(feed.feed_url).to eq("https://example.com/feed.xml")
      expect(feed.name).to eq("My Blog")
      expect(feed.user).to eq(user)
      expect(response).to redirect_to(user_settings_path("extensions"))
    end

    it "shows error for invalid feed_url" do
      allow(Feeds::ValidateUrl).to receive(:call).and_return(false)

      expect do
        post rss_feeds_path, params: {
          rss_feed: { feed_url: "https://bad.example.com/not-a-feed" }
        }
      end.not_to change(RssFeed, :count)

      expect(flash[:error]).to be_present
    end

    it "rejects duplicate feed_url for same user" do
      allow(Feeds::ValidateUrl).to receive(:call).and_return(true)
      create(:rss_feed, user: user, feed_url: "https://example.com/feed.xml")

      expect do
        post rss_feeds_path, params: {
          rss_feed: { feed_url: "https://example.com/feed.xml" }
        }
      end.not_to change(RssFeed, :count)
    end
  end

  describe "PATCH /rss_feeds/:id" do
    it "updates the rss feed" do
      feed = create(:rss_feed, user: user)
      allow(Feeds::ValidateUrl).to receive(:call).and_return(true)

      patch rss_feed_path(feed), params: {
        rss_feed: { name: "Updated Name", mark_canonical: true }
      }

      feed.reload
      expect(feed.name).to eq("Updated Name")
      expect(feed.mark_canonical).to be(true)
      expect(response).to redirect_to(user_settings_path("extensions"))
    end

    it "rejects update by non-owner" do
      other_user = create(:user)
      feed = create(:rss_feed, user: other_user)

      expect do
        patch rss_feed_path(feed), params: {
          rss_feed: { name: "Hacked" }
        }
      end.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  describe "DELETE /rss_feeds/:id" do
    it "deletes the rss feed" do
      feed = create(:rss_feed, user: user)

      expect do
        delete rss_feed_path(feed)
      end.to change(RssFeed, :count).by(-1)

      expect(response).to redirect_to(user_settings_path("extensions"))
    end

    it "rejects delete by non-owner" do
      other_user = create(:user)
      feed = create(:rss_feed, user: other_user)

      expect do
        delete rss_feed_path(feed)
      end.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  describe "POST /rss_feeds/:id/fetch" do
    it "queues feed import" do
      feed = create(:rss_feed, user: user)

      sidekiq_assert_enqueued_with(job: Feeds::ImportArticlesWorker) do
        post fetch_rss_feed_path(feed)
      end

      expect(response).to redirect_to(user_settings_path("extensions"))
      expect(flash[:settings_notice]).to be_present
    end

    it "rejects fetch by non-owner" do
      other_user = create(:user)
      feed = create(:rss_feed, user: other_user)

      expect do
        post fetch_rss_feed_path(feed)
      end.to raise_error(Pundit::NotAuthorizedError)
    end
  end
end
