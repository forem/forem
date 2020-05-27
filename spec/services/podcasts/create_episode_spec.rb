require "rails_helper"
require "rss"
require "rss/itunes"

RSpec.describe Podcasts::CreateEpisode, type: :service do
  let!(:podcast) { create(:podcast) }

  context "when item has an https media_url" do
    let(:rss_item) { RSS::Parser.parse("spec/support/fixtures/podcasts/developertea.rss", false).items.first }
    let!(:item) { Podcasts::EpisodeRssItem.from_item(rss_item) }

    before do
      stub_request(:head, item.enclosure_url).to_return(status: 200)
    end

    xit "creates an episode" do
      expect do
        described_class.call(podcast.id, item)
      end.to change(PodcastEpisode, :count).by(1)
    end

    xit "indexes the episode" do
      sidekiq_perform_enqueued_jobs { described_class.call(podcast.id, item) }
      expect { podcast.podcast_episodes.each(&:elasticsearch_doc) }.not_to raise_error
    end

    xit "creates an episode with correct data" do
      episode = described_class.call(podcast.id, item)
      expect(episode.title).to eq("Individual Contributor Career Growth w/ Matt Klein (part 1)")
      expect(episode.podcast_id).to eq(podcast.id)
      expect(episode.website_url).to eq("http://developertea.simplecast.fm/50464d4b")
      expect(episode.guid).to include("53b17a1e-271b-40e3-a084-a67b4fcba562")
    end

    xit "sets correct availability statuses" do
      episode = described_class.call(podcast.id, item)
      expect(episode.https?).to be true
      expect(episode.reachable).to be true
    end

    xit "rescues an exception when pubDate is invalid" do
      allow(item).to receive(:pubDate).and_return("not a date, haha")
      episode = described_class.call(podcast.id, item)
      expect(episode).to be_persisted
      expect(episode.published_at).to eq(nil)
    end

    xit "rescues an exception when pubDate is nil" do
      allow(item).to receive(:pubDate).and_return(nil)
      episode = described_class.call(podcast.id, item)
      expect(episode).to be_persisted
      expect(episode.published_at).to eq(nil)
    end
  end

  context "when item has an http media url" do
    let(:rss_item) { RSS::Parser.parse("spec/support/fixtures/podcasts/awayfromthekeyboard.rss", false).items.first }
    let!(:item) { Podcasts::EpisodeRssItem.from_item(rss_item) }
    let(:https_url) { "https://awayfromthekeyboard.com/wp-content/uploads/2018/02/Episode_075_Lara_Hogan_Demystifies_Public_Speaking.mp3" }

    xit "sets media_url to https version when it is available" do
      stub_request(:head, https_url).to_return(status: 200)
      episode = described_class.call(podcast.id, item)
      expect(episode.media_url).to eq(https_url)
      expect(episode.https?).to be true
      expect(episode.reachable).to be true
    end

    xit "keeps an http media url when https version is not available" do
      stub_request(:head, https_url).to_return(status: 404)
      stub_request(:head, item.enclosure_url).to_return(status: 200)
      episode = described_class.call(podcast.id, item)
      expect(episode.media_url).to eq(item.enclosure_url)
      expect(episode.https?).to be false
      expect(episode.reachable).to be true
    end
  end

  context "when attempting to create duplicate episodes" do
    let(:rss_item) { RSS::Parser.parse("spec/support/fixtures/podcasts/developertea.rss", false).items.first }
    let(:item) { Podcasts::EpisodeRssItem.from_item(rss_item) }
    let!(:episode) { create(:podcast_episode, title: "outdated title", media_url: item.enclosure_url) }

    before do
      stub_request(:head, item.enclosure_url).to_return(status: 200)
    end

    xit "updates existing episode" do
      new_episode = described_class.call(podcast.id, item)
      expect(new_episode.id).to eq(episode.id)
    end

    xit "updates columns" do
      new_episode = described_class.call(podcast.id, item)
      expect(new_episode.title).to eq(item.title)
    end
  end
end
