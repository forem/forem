require "rails_helper"

RSpec.describe Listings::BustCacheWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "high_priority", 1

  describe "#perform" do
    let(:worker) { subject }

    before do
      allow(EdgeCache::BustListings).to receive(:call)
    end

    context "with listing" do
      let(:listing) { double }
      let(:listing_id) { 1 }

      before do
        allow(Listing).to receive(:find_by).with(id: listing_id).and_return(listing)
      end

      it "busts cache" do
        worker.perform(listing_id)

        expect(EdgeCache::BustListings).to have_received(:call).with(listing)
      end
    end

    describe "when no listing is found" do
      it "does not error" do
        expect { worker.perform(nil) }.not_to raise_error
      end

      it "does not bust cache" do
        worker.perform(nil)
        expect(EdgeCache::BustListings).not_to have_received(:call)
      end
    end
  end
end
