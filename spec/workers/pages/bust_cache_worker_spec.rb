require "rails_helper"

RSpec.describe Pages::BustCacheWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "high_priority", 1

  describe "#perform" do
    let(:worker) { subject }
    let(:page_slug) { "test123" }

    it "with empty slug does not call the cache buster" do
      allow(EdgeCache::BustPage).to receive(:call)
      worker.perform("")
      expect(EdgeCache::BustPage).not_to have_received(:call)
    end

    it "busts the cache" do
      allow(EdgeCache::BustPage).to receive(:call).with(page_slug, organization: nil)
      worker.perform(page_slug)
      expect(EdgeCache::BustPage).to have_received(:call).with(page_slug, organization: nil)
    end

    it "passes the organization to the cache buster when an organization id is given" do
      organization = create(:organization)
      allow(EdgeCache::BustPage).to receive(:call)
      worker.perform(page_slug, organization.id)
      expect(EdgeCache::BustPage).to have_received(:call).with(page_slug, organization: organization)
    end

    it "busts the cache without an organization when the organization no longer exists" do
      allow(EdgeCache::BustPage).to receive(:call)
      worker.perform(page_slug, Organization.maximum(:id).to_i + 1)
      expect(EdgeCache::BustPage).to have_received(:call).with(page_slug, organization: nil)
    end
  end
end
