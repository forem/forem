require "rails_helper"

RSpec.describe Podcasts::UpdateEpisode, type: :service do
  let(:podcast) { create(:podcast) }
  let(:enclosure) { instance_double("RSS::Rss::Channel::Item::Enclosure", url: "https://audio.simplecast.com/2330f132.mp3") }
  let(:item) { instance_double("RSS::Rss::Channel::Item", pubDate: "2019-06-19", enclosure: enclosure) }

  it "updates published_at if it's nil" do
    episode = create(:podcast_episode, podcast: podcast, published_at: nil)
    described_class.call(episode, item)
    episode.reload
    expect(episode.published_at).to be_truthy
  end

  it "updates media_url if the item url contains https" do
    episode = create(:podcast_episode, podcast: podcast, media_url: "http://audio.simplecast.com/2330f132.mp3")
    described_class.call(episode, item)
    episode.reload
    expect(episode.media_url).to eq("https://audio.simplecast.com/2330f132.mp3")
  end

  it "catches expception when pubDate is invalid" do
    invalid_item = instance_double("RSS::Rss::Channel::Item", pubDate: "i'm not a date", enclosure: enclosure)

    episode = create(:podcast_episode, podcast: podcast, published_at: nil)
    described_class.call(episode, invalid_item)
    expect(episode.published_at).to be_nil
  end

  it "does fine when there's nothing to update" do
    published_at = Time.current - 1.day
    episode = create(:podcast_episode, podcast: podcast, media_url: "https://audio.simplecast.com/100.mp3", published_at: published_at)
    described_class.call(episode, item)
    episode.reload
    expect(episode.media_url).to eq("https://audio.simplecast.com/100.mp3")
    expect(episode.published_at.strftime("%Y-%m-%d")).to eq(published_at.strftime("%Y-%m-%d"))
  end
end
