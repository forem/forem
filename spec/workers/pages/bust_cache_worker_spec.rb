require "rails_helper"

class NewPageBuster
  def self.bust_page(*); end
end

RSpec.describe Pages::BustCacheWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "high_priority", 1

  describe "#perform" do
    let(:worker) { subject }
    let(:page_slug) { "test123" }

    it "with empty slug does not call the cache buster" do
      allow(CacheBuster).to receive(:bust_page)
      worker.perform("")
      expect(CacheBuster).not_to have_received(:bust_page)
    end

    it "with cache buster defined busts cache with defined buster" do
      allow(NewPageBuster).to receive(:bust_page)
      worker.perform(page_slug, "NewPageBuster")
      expect(NewPageBuster).to have_received(:bust_page).with(page_slug)
    end

    it "without cache buster defined busts cache with default" do
      allow(CacheBuster).to receive(:bust_page)
      worker.perform(page_slug)
      expect(CacheBuster).to have_received(:bust_page).with(page_slug)
    end
  end
end
