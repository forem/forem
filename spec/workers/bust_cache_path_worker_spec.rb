require "rails_helper"

RSpec.describe BustCachePathWorker, type: :worker do
  let(:worker) { subject }

  include_examples "#enqueues_on_correct_queue", "high_priority"

  describe "#perform" do
    it "busts cache for given path" do
      allow(CacheBuster).to receive(:bust)
      worker.perform("/foo")
      expect(CacheBuster).to have_received(:bust).with("/foo")
    end
  end
end
