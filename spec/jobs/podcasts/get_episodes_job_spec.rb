require "rails_helper"

RSpec.describe Podcasts::GetEpisodesJob, type: :job do
  include_examples "#enqueues_job", "podcasts_get_episodes", [1, 4]

  describe "#perform_now" do
    let(:feed) { double }
    let(:podcast) { create(:podcast) }

    before do
      allow(feed).to receive(:get_episodes)
    end

    it "calls the service" do
      described_class.perform_now(podcast_id: podcast.id, limit: 5, feed: feed, force_update: true)
      expect(feed).to have_received(:get_episodes).with(podcast: podcast, limit: 5, force_update: true).once
    end

    it "doesn't call the service when the podcast is not found" do
      described_class.perform_now(podcast_id: Podcast.maximum(:id).to_i + 1, limit: 5, feed: feed)
      expect(feed).not_to have_received(:get_episodes)
    end
  end
end
