require "rails_helper"

vcr_option = {
  cassette_name: "se_daily_rss_feed",
  allow_playback_repeats: "true",
}

RSpec.describe PodcastFeed, vcr: vcr_option do
  let(:feed_url) { "http://softwareengineeringdaily.com/feed/podcast/" }
  let(:podcast) { create(:podcast, feed_url: feed_url) }

  before do
    podcast
  end

  it "fetches podcast episodes" do
    PodcastFeed.new.get_episodes(podcast, 2)
    expect(PodcastEpisode.all.size).to eq(2)
  end

  it "does not refetch already fetched episodes" do
    2.times { PodcastFeed.new.get_episodes(podcast, 2) }
    expect(PodcastEpisode.all.size).to eq(2)
  end
end
