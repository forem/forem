require "rails_helper"

RSpec.describe Events::BustCacheWorker do
  include_examples "#enqueues_on_correct_queue", "low_priority"

  describe "#perform" do
    it "busts cache" do
      allow(EdgeCache::BustEvents).to receive(:call)
      described_class.new.perform
      expect(EdgeCache::BustEvents).to have_received(:call)
    end
  end
end
