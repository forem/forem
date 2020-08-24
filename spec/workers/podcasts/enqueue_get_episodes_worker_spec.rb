require "rails_helper"

RSpec.describe Podcasts::EnqueueGetEpisodesWorker, type: :worker do
  let(:worker) { subject }

  include_examples "#enqueues_on_correct_queue", "medium_priority"

  describe "#perform" do
    it "enqueues Podcasts::GetEpisodesWorker" do
      create(:podcast, published: true)
      worker.perform
      sidekiq_assert_enqueued_jobs(1, only: Podcasts::GetEpisodesWorker)
    end
  end
end
