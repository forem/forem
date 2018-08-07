require "rails_helper"

vcr_option = {
  cassette_name: "se_daily_rss_feed",
  allow_playback_repeats: "true",
}

RSpec.describe "ArticlesApi", type: :request, vcr: vcr_option do
  let(:podcast) { create(:podcast, feed_url: "http://softwareengineeringdaily.com/feed/podcast/") }

  before do
    PodcastFeed.new.get_episodes(podcast, 2)
  end

  describe "GET /api/articles" do
    it "returns json response" do
      get "/api/podcast_episodes"
      expect(response.content_type).to eq("application/json")
    end

    it "returns podcast episodes" do
      get "/api/podcast_episodes"
      expect(JSON.parse(response.body).size).to eq(2)
    end

    it "returns podcast episodes of specific podcast if passed username" do
      get "/api/podcast_episodes?username=#{podcast.slug}"
      expect(JSON.parse(response.body).size).to eq(2)
    end

    it "returns nothing is passed invalid podcast slug" do
      expect { get "/api/podcast_episodes?username=nothing_#{rand(1000000000000000)}" }.
        to raise_error(ActionController::RoutingError)
    end
  end
end
