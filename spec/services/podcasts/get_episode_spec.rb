require "rails_helper"

RSpec.describe Podcasts::GetEpisode do
  let(:podcast) { create(:podcast) }
  let(:episode) { create(:podcast_episode, podcast: podcast) }
  let(:enclosure) { instance_double("RSS::Rss::Channel::Item::Enclosure", url: "https://audio.simplecast.com/2330f132.mp3") }
  let(:item) do
    instance_double("RSS::Rss::Channel::Item", pubDate: "2019-06-19",
                                               enclosure: enclosure,
                                               description: "yet another podcast",
                                               title: "lightalloy's podcast",
                                               guid: "<guid isPermaLink=\"false\">http://podcast.example/file.mp3</guid>",
                                               itunes_subtitle: "hello",
                                               content_encoded: nil,
                                               itunes_summary: "world",
                                               link: "https://litealloy.ru")
  end

  it "calls UpdateEpisode when an episode exists" do
    update = double
    allow(update).to receive(:call)
    allow(podcast).to receive(:existing_episode).and_return(episode)
    described_class.new(podcast, update).call(item)
    expect(update).to have_received(:call).with(episode, item)
  end

  it "schedules a Create job when episode doesn't exist" do
    allow(podcast).to receive(:existing_episode).and_return(nil)
    expect do
      described_class.new(podcast).call(item)
    end.to have_enqueued_job.on_queue("podcast_episode_create") # .with(podcast.id)
  end
end
