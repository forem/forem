require "rails_helper"

RSpec.describe Podcasts::UpdateEpisodeMediaUrl, type: :service do
  let(:podcast) { create(:podcast) }

  it "updates media_url from http to https" do
    http_url = "http://example.com/1.mp3"
    https_url = "https://example.com/1.mp3"
    stub_request(:head, https_url).to_return(status: 200)

    episode = create(:podcast_episode, podcast: podcast, media_url: "http://example.com/1.mp3")
    described_class.call(episode, http_url)
    episode.reload
    expect(episode.media_url).to eq(https_url)
    expect(episode.reachable).to be true
    expect(episode.https).to be true
  end

  it "keeps http when https and http are not reachable" do
    http_url = "http://example.com/1.mp3"
    https_url = "https://example.com/1.mp3"
    allow(HTTParty).to receive(:head).with(http_url).and_raise(Errno::ECONNREFUSED)
    allow(HTTParty).to receive(:head).with(https_url).and_raise(Errno::ECONNREFUSED)

    episode = create(:podcast_episode, podcast: podcast, media_url: http_url)
    described_class.call(episode, http_url)
    episode.reload
    expect(episode.media_url).to eq(http_url)
    expect(episode.reachable).to be false
    expect(episode.https).to be false
  end

  it "does fine when there's nothing to update" do
    url = "https://audio.simplecast.com/100.mp3"
    stub_request(:head, url).to_return(status: 200)
    episode = create(:podcast_episode, podcast: podcast, media_url: url)
    described_class.call(episode, url)
    episode.reload
    expect(episode.media_url).to eq(url)
    expect(episode.reachable).to be true
    expect(episode.https).to be true
  end
end
