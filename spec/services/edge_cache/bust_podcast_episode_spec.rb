require "rails_helper"

RSpec.describe EdgeCache::BustPodcastEpisode, type: :service do
  let(:podcast) { create(:podcast) }
  let(:podcast_episode) { create(:podcast_episode, podcast_id: podcast.id) }
  let(:podcast_path) { "/cfp" }
  let(:podcast_slug) { "-007" }
  let(:paths) do
    [
      podcast_path,
      "/#{podcast_slug}",
      "/pod",
    ]
  end

  before do
    podcast_episode
    allow(EdgeCache::PurgeByKey).to receive(:call)
  end

  it "purges podcast episode, podcast, and podcast index surrogate keys in one call" do
    described_class.call(podcast_episode, podcast_path, podcast_slug)

    expect(EdgeCache::PurgeByKey).to have_received(:call).with(
      [podcast_episode.record_key, podcast_episode.table_key, "podcast_episodes_all", "podcasts/#{podcast_slug}"],
      fallback_paths: paths,
    ).once
  end

  it "logs an error if purging raises" do
    allow(Rails.logger).to receive(:warn)
    allow(EdgeCache::PurgeByKey).to receive(:call).and_raise(StandardError)

    described_class.call(podcast_episode, podcast_path, podcast_slug)

    expect(Rails.logger).to have_received(:warn).once
  end
end
