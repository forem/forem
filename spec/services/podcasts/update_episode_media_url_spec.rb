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

    expect(episode).to have_attributes(reachable: true, https: true, media_url: https_url)
  end

  it "keeps http when https and http are not reachable" do
    http_url = "http://example.com/1.mp3"
    https_url = "https://example.com/1.mp3"
    options = { timeout: Podcasts::GetMediaUrl::TIMEOUT }
    allow(HTTParty).to receive(:head).with(http_url, options).and_raise(Errno::ECONNREFUSED)
    allow(HTTParty).to receive(:head).with(https_url, options).and_raise(Errno::ECONNREFUSED)

    episode = create(:podcast_episode, podcast: podcast, media_url: http_url)
    described_class.call(episode, http_url)
    episode.reload

    expect(episode).to have_attributes(reachable: false, https: false, media_url: http_url)
  end

  it "does fine when there's nothing to update" do
    url = "https://audio.simplecast.com/100.mp3"
    stub_request(:head, url).to_return(status: 200)
    episode = create(:podcast_episode, podcast: podcast, media_url: url)
    described_class.call(episode, url)
    episode.reload

    expect(episode).to have_attributes(reachable: true, https: true, media_url: url)
  end
end
