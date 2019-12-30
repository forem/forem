require "rails_helper"

RSpec.describe Events::BustCacheJob do
  include_examples "#enqueues_job", "events_bust_cache"

  describe "#perform_now" do
    let(:cache_buster) { class_double(CacheBuster) }

    before do
      allow(cache_buster).to receive(:bust_events)
    end

    it "busts cache" do
      described_class.perform_now(cache_buster)

      expect(cache_buster).to have_received(:bust_events)
    end
  end
end
