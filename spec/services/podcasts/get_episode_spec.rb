require "rails_helper"
require "rss"

RSpec.describe Podcasts::GetEpisode do
  let(:podcast) { create(:podcast) }
  let(:episode) { create(:podcast_episode, podcast: podcast) }
  let(:item) do
    build(:podcast_episode_rss_item, pubDate: "2019-06-19",
                                     enclosure_url: "https://audio.simplecast.com/2330f132.mp3",
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

  context "when feed doesn't contain enclosure urls" do
    let!(:item) { RSS::Parser.parse("spec/support/fixtures/podcasts/arresteddevops.xml", false).items.first }

    before do
      allow(podcast).to receive(:existing_episode).and_return(nil)
    end

    it "doesn't create invalid episodes" do
      perform_enqueued_jobs do
        expect do
          described_class.new(podcast).call(item)
        end.not_to change(PodcastEpisode, :count)
      end
    end

    it "doesn't schedule jobs" do
      expect do
        described_class.new(podcast).call(item)
      end.not_to have_enqueued_job
    end
  end
end
