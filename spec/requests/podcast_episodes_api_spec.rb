require "rails_helper"

vcr_option = {
  cassette_name: "se_daily_rss_feed",
  allow_playback_repeats: "true"
}

RSpec.describe "ArticlesApi", type: :request, vcr: vcr_option do
  let(:podcast) { create(:podcast, feed_url: "http://softwareengineeringdaily.com/feed/podcast/") }

  before do
    stub_request(:head, "https://traffic.libsyn.com/sedaily/AnalyseAsia.mp3").to_return(status: 200)
    stub_request(:head, "https://traffic.libsyn.com/sedaily/IFTTT.mp3").to_return(status: 200)

    perform_enqueued_jobs do
      Podcasts::Feed.new.get_episodes(podcast, 2)
    end
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
      get "/api/podcast_episodes?username=nothing_#{rand(1_000_000_000_000_000)}"
      expect(response).to have_http_status(:not_found)
    end
  end
end
