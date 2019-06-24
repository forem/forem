require "rails_helper"

vcr_option = {
  cassette_name: "se_daily_rss_feed",
  allow_playback_repeats: "true"
}

RSpec.describe Podcasts::Feed, vcr: vcr_option do
  let(:feed_url) { "http://softwareengineeringdaily.com/feed/podcast/" }
  let(:podcast) { create(:podcast, feed_url: feed_url) }

  before do
    podcast
  end

  context "when creating" do
    before do
      stub_request(:head, "https://traffic.libsyn.com/sedaily/AnalyseAsia.mp3").to_return(status: 200)
      stub_request(:head, "https://traffic.libsyn.com/sedaily/IFTTT.mp3").to_return(status: 200)
    end

    it "fetches podcast episodes" do
      expect do
        described_class.new.get_episodes(podcast, 2)
      end.to change(PodcastEpisode, :count).by(2)
    end

    it "fetches correct podcasts" do
      described_class.new.get_episodes(podcast, 2)
      episodes = podcast.podcast_episodes
      expect(episodes.pluck(:title).sort).to eq(["Analyse Asia with Bernard Leong", "IFTTT Architecture with Nicky Leach"])
      expect(episodes.pluck(:media_url).sort).to eq(%w[https://traffic.libsyn.com/sedaily/AnalyseAsia.mp3 https://traffic.libsyn.com/sedaily/IFTTT.mp3])
    end
  end

  context "when updating" do
    let!(:episode) { create(:podcast_episode, media_url: "http://traffic.libsyn.com/sedaily/AnalyseAsia.mp3", title: "Old Title", published_at: nil) }
    let!(:episode2) { create(:podcast_episode, media_url: "http://traffic.libsyn.com/sedaily/IFTTT.mp3", title: "SuperPodcast", published_at: nil) }

    it "does not refetch already fetched episodes" do
      expect do
        described_class.new.get_episodes(podcast, 2)
      end.not_to change(PodcastEpisode, :count)
    end

    it "updates published_at for existing episodes" do
      described_class.new.get_episodes(podcast, 2)
      episode.reload
      episode2.reload
      expect(episode.published_at).to be_truthy
      expect(episode2.published_at).to be_truthy
    end
  end
end
