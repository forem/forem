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
    paths.each do |path|
      allow(described_class).to receive(:bust).with(path).once
    end

    allow(podcast_episode).to receive(:purge)
    allow(podcast_episode).to receive(:purge_all)
  end

  it "busts the cache" do
    described_class.call(podcast_episode, podcast_path, podcast_slug)

    paths.each do |path|
      expect(described_class).to have_received(:bust).with(path).once
    end

    expect(podcast_episode).to have_received(:purge)
    expect(podcast_episode).to have_received(:purge_all)
  end

  it "logs an error" do
    allow(Rails.logger).to receive(:warn)
    allow(described_class).to receive(:bust).and_raise(StandardError)
    described_class.call(podcast_episode, 12, podcast_slug)
    expect(Rails.logger).to have_received(:warn).once
  end
end
