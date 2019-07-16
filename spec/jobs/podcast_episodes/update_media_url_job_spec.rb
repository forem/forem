require "rails_helper"

RSpec.describe PodcastEpisodes::UpdateMediaUrlJob, type: :job do
  include_examples "#enqueues_job", "podcast_episode_update", 1, "https://example.com/"

  describe "#perform_now" do
    let(:feed) { double }
    let(:episode) { create(:podcast_episode) }
    let(:url) { Faker::Internet.url }
    let(:updater) { double }

    before do
      allow(updater).to receive(:call)
    end

    it "calls the service" do
      described_class.perform_now(episode.id, url, updater)
      expect(updater).to have_received(:call).with(episode, url).once
    end

    it "doesn't call the service when the podcast is not found" do
      described_class.perform_now(PodcastEpisode.maximum(:id).to_i + 1, url, updater)
      expect(updater).not_to have_received(:call)
    end
  end
end
