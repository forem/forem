require "rails_helper"

RSpec.describe PodcastEpisodes::UpdateMediaUrlWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "medium_priority", [212, "https://devto.australianopen.com"]

  describe "#perform" do
    let(:worker) { subject }
    let(:feed) { double }
    let(:episode) { create(:podcast_episode) }
    let(:url) { Faker::Internet.url }

    before do
      allow(Podcasts::UpdateEpisodeMediaUrl).to receive(:call)
    end

    it "calls the service" do
      worker.perform(episode.id, url)
      expect(Podcasts::UpdateEpisodeMediaUrl).to have_received(:call).with(episode, url).once
    end

    it "raises an error if episode is not found" do
      expect do
        worker.perform(PodcastEpisode.maximum(:id).to_i + 1, url)
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
