require "rails_helper"

RSpec.describe Podcasts::GetEpisodesJob, type: :job do
  include_examples "#enqueues_job", "podcasts_get_episodes", podcast_id: 10

  describe "#perform_now" do
    let(:podcast) { create(:podcast) }
    let(:feed) { instance_double(Podcasts::Feed) }

    before do
      allow(Podcasts::Feed).to receive(:new).and_return(feed)
      allow(feed).to receive(:get_episodes)
    end

    it "calls the service" do
      described_class.perform_now(podcast_id: podcast.id, limit: 5, force_update: true)
      expect(feed).to have_received(:get_episodes)
    end

    it "doesn't call the service when the podcast is not found" do
      described_class.perform_now(podcast_id: Podcast.maximum(:id).to_i + 1, limit: 5)
      expect(feed).not_to have_received(:get_episodes)
    end
  end
end
