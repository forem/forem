require "rails_helper"

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

  let(:get_episode) { described_class.new(podcast) }

  context "when episode exists" do
    # it "calls UpdateEpisode when an episode exists" do
    #   update = double
    #   allow(update).to receive(:call)
    #   allow(podcast).to receive(:existing_episode).and_return(episode)
    #   described_class.new(podcast, update).call(item)
    #   expect(update).to have_received(:call).with(episode, item)
    # end

    it "schedules an Update job when published_at is null" do
      ep = create(:podcast_episode, published_at: nil, reachable: true, https: true, podcast: podcast)
      allow(podcast).to receive(:existing_episode).and_return(ep)
      expect do
        get_episode.call(item)
      end.to have_enqueued_job.on_queue("podcast_episode_update")
    end

    it "schedules an Update job when media_url wasn't available by https" do
      ep = create(:podcast_episode, published_at: Time.current, reachable: true, https: false, podcast: podcast)
      allow(podcast).to receive(:existing_episode).and_return(ep)
      expect do
        get_episode.call(item)
      end.to have_enqueued_job.on_queue("podcast_episode_update")
    end

    it "doesn't schedule a job when episode wasn't reachable" do
      ep = create(:podcast_episode, published_at: Time.current, reachable: false, https: true, podcast: podcast)
      allow(podcast).to receive(:existing_episode).and_return(ep)
      expect do
        get_episode.call(item)
      end.to have_enqueued_job.on_queue("podcast_episode_update")
    end

    it "doesn't schedule a job when everything is ok" do
      ep = create(:podcast_episode, published_at: Time.current, reachable: true, https: true, podcast: podcast)
      allow(podcast).to receive(:existing_episode).and_return(ep)
      expect do
        get_episode.call(item)
      end.not_to have_enqueued_job
    end
  end

  it "schedules a Create job when an episode doesn't exist" do
    allow(podcast).to receive(:existing_episode).and_return(nil)
    expect do
      described_class.new(podcast).call(item)
    end.to have_enqueued_job.on_queue("podcast_episode_create") # .with(podcast.id)
  end
end
