require "rails_helper"

RSpec.describe GithubRepos::UpdateLatestWorker, type: :worker do
  let(:worker) { subject }

  include_examples "#enqueues_on_correct_queue", "medium_priority"

  describe "#perform" do
    it "update latest GithubRepos" do
      allow(GithubRepo).to receive(:update_to_latest)
      worker.perform
      expect(GithubRepo).to have_received(:update_to_latest)
    end
  end
end
