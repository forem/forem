require "rails_helper"

RSpec.describe Podcasts::GetEpisodesJob, type: :job do
  include_examples "#enqueues_job", "podcasts_get_episodes", [1, 4]

  describe "#perform_now" do
    let(:podcast) { create(:podcast) }

    FakeFeed = Struct.new(:podcast) do
      def get_episodes; end
    end

    it "calls the service" do
      described_class.perform_now(podcast_id: podcast.id, limit: 5, feed: FakeFeed, force_update: true)
      expect(FakeFeed).to have_received(:new).with(podcast)
    end

    it "doesn't call the service when the podcast is not found" do
      described_class.perform_now(podcast_id: Podcast.maximum(:id).to_i + 1, limit: 5, feed: FakeFeed)
      expect(FakeFeed).not_to have_received(:new).with(podcast)
    end
  end
end
