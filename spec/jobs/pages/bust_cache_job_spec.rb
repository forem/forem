require "rails_helper"

RSpec.describe Pages::BustCacheJob do
  let(:cache_buster) { instance_double(CacheBuster) }

  before do
    allow(CacheBuster).to receive(:new).and_return(cache_buster)
    allow(cache_buster).to receive(:bust_page)
  end

  include_examples "#enqueues_job", "pages_bust_cache", "SlUg"

  describe "#perform_now" do
    it "busts cache" do
      described_class.perform_now("SlUg", cache_buster)
      expect(cache_buster).to have_received(:bust_page).with("SlUg")
    end
  end
end
