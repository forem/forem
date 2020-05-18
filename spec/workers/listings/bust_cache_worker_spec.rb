require "rails_helper"

RSpec.describe Listings::BustCacheWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "high_priority", 1

  describe "#perform" do
    let(:worker) { subject }

    before do
      allow(CacheBuster).to receive(:bust_listings)
    end

    context "with listing" do
      let(:listing) { double }
      let(:listing_id) { 1 }

      before do
        allow(Listing).to receive(:find_by).with(id: listing_id).and_return(listing)
      end

      it "busts cache" do
        worker.perform(listing_id)

        expect(CacheBuster).to have_received(:bust_listings).with(listing)
      end
    end

    describe "when no listing is found" do
      it "does not error" do
        expect { worker.perform(nil) }.not_to raise_error
      end

      it "does not bust cache" do
        worker.perform(nil)
        expect(CacheBuster).not_to have_received(:bust_listings)
      end
    end
  end
end
