require "rails_helper"
require "rss"
require "rss/itunes"

RSpec.describe Podcasts::CreateEpisode, type: :service do
  let!(:podcast) { create(:podcast) }

  context "when item has an https media_url" do
    let!(:item) { RSS::Parser.parse("spec/support/fixtures/developertea.rss", false).items.first }

    before do
      stub_request(:head, item.enclosure.url).to_return(status: 200)
    end

    it "creates an episode" do
      expect do
        described_class.call(podcast.id, item)
      end.to change(PodcastEpisode, :count).by(1)
    end

    it "creates an episode with correct data" do
      episode = described_class.call(podcast.id, item)
      expect(episode.title).to eq("Individual Contributor Career Growth w/ Matt Klein (part 1)")
      expect(episode.podcast_id).to eq(podcast.id)
      expect(episode.website_url).to eq("http://developertea.simplecast.fm/50464d4b")
      expect(episode.guid).to include("53b17a1e-271b-40e3-a084-a67b4fcba562")
    end

    it "rescues an exception when pubDate is invalid" do
      allow(item).to receive(:pubDate).and_return("not a date, haha")
      episode = described_class.call(podcast.id, item)
      expect(episode).to be_persisted
      expect(episode.published_at).to eq(nil)
    end
  end

  context "when item has an http media url" do
    let!(:item) { RSS::Parser.parse("spec/support/fixtures/awayfromthekeyboard.rss", false).items.first }
    let(:https_url) {  "https://awayfromthekeyboard.com/wp-content/uploads/2018/02/Episode_075_Lara_Hogan_Demystifies_Public_Speaking.mp3" }

    it "sets media_url to https version when it is available" do
      stub_request(:head, https_url).to_return(status: 200)
      episode = described_class.call(podcast.id, item)
      expect(episode.media_url).to eq(https_url)
    end

    it "keeps an http media url when https version is not available" do
      stub_request(:head, https_url).to_return(status: 404)
      episode = described_class.call(podcast.id, item)
      expect(episode.media_url).to eq(item.enclosure.url)
    end

    # enable when the logic will not rely solely on exception
    xit "sets status notice when https version is not available" do
      stub_request(:head, https_url).to_return(status: 404)
      described_class.call(podcast.id, item)
      podcast.reload
      expect(podcast.status_notice).to include("may not be playable")
    end
  end
end
