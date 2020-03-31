require "rails_helper"
require "rss"

RSpec.describe Podcasts::GetEpisode, type: :service do
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
    it "enqueues a worker to update url when media url wasn't available by https" do
      ep = create(:podcast_episode, published_at: Time.current, reachable: true, https: false, podcast: podcast)
      allow(podcast).to receive(:existing_episode).and_return(ep)

      expect do
        get_episode.call(item: item)
      end.to change { PodcastEpisodes::UpdateMediaUrlWorker.jobs.size }.by(1)
    end

    it "enqueues a worker when episode isn't reachable" do
      ep = create(:podcast_episode, published_at: Time.current, reachable: false, https: true, podcast: podcast)
      allow(podcast).to receive(:existing_episode).and_return(ep)

      expect do
        get_episode.call(item: item)
      end.to change { PodcastEpisodes::UpdateMediaUrlWorker.jobs.size }
    end

    it "doesn't schedule a worker when the media url is ok" do
      ep = create(:podcast_episode, published_at: nil, reachable: true, https: true, podcast: podcast)
      allow(podcast).to receive(:existing_episode).and_return(ep)

      expect do
        get_episode.call(item: item)
      end.not_to change { PodcastEpisodes::UpdateMediaUrlWorker.jobs.size }
    end

    it "doesn't schedule a job when an episode was created long ago" do
      ep = create(:podcast_episode, published_at: Time.current, reachable: true, https: false, podcast: podcast)
      ep.update_columns(created_at: 2.days.ago)
      allow(podcast).to receive(:existing_episode).and_return(ep)
      sidekiq_assert_no_enqueued_jobs only: PodcastEpisodes::UpdateMediaUrlWorker do
        get_episode.call(item: item)
      end
    end

    it "updates published_at when it was nil" do
      ep = create(:podcast_episode, published_at: nil, podcast: podcast)
      allow(podcast).to receive(:existing_episode).and_return(ep)
      get_episode.call(item: item)
      ep.reload
      expect(ep.published_at.strftime("%Y-%m-%d")).to eq("2019-06-19")
    end

    it "sets published_at to nil if it is invalid" do
      item2 = build(:podcast_episode_rss_item, pubDate: "hello, robot")
      ep = create(:podcast_episode, published_at: nil, podcast: podcast)
      allow(podcast).to receive(:existing_episode).and_return(ep)
      get_episode.call(item: item2)
      ep.reload
      expect(ep.published_at).to eq(nil)
    end

    it "enqueues a worker when force_update is passed" do
      ep = create(:podcast_episode, published_at: Time.current, reachable: true, https: true, podcast: podcast)
      allow(podcast).to receive(:existing_episode).and_return(ep)
      expect do
        get_episode.call(item: item, force_update: true)
      end.to change { PodcastEpisodes::UpdateMediaUrlWorker.jobs.size }.by(1)
    end
  end

  it "enqueues a worker to create an episode when it doesn't exist" do
    allow(podcast).to receive(:existing_episode).and_return(nil)

    sidekiq_assert_enqueued_with(job: PodcastEpisodes::CreateWorker, args: [podcast.id, item.to_h]) do
      described_class.new(podcast).call(item: item)
    end
  end

  context "when feed doesn't contain enclosure urls" do
    let!(:item) { RSS::Parser.parse("spec/support/fixtures/podcasts/arresteddevops.xml", false).items.first }

    before do
      allow(podcast).to receive(:existing_episode).and_return(nil)
    end

    it "doesn't create invalid episodes" do
      sidekiq_perform_enqueued_jobs do
        expect do
          described_class.new(podcast).call(item: item)
        end.not_to change(PodcastEpisode, :count)
      end
    end

    it "doesn't schedule jobs" do
      sidekiq_assert_no_enqueued_jobs do
        described_class.new(podcast).call(item: item)
      end
    end
  end
end
