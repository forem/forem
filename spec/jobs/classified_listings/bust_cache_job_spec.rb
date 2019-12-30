require "rails_helper"

RSpec.describe ClassifiedListings::BustCacheJob, type: :job do
  include_examples "#enqueues_job", "classified_listings_bust_cache", 1

  describe "#perform_now" do
    let(:cache_buster) { double }

    before do
      allow(cache_buster).to receive(:bust_classified_listings)
    end

    context "with listing" do
      let_it_be(:listing) { double }
      let_it_be(:listing_id) { 1 }

      before do
        allow(ClassifiedListing).to receive(:find_by).with(id: listing_id).and_return(listing)
      end

      it "busts cache" do
        described_class.perform_now(listing_id, cache_buster)

        expect(cache_buster).to have_received(:bust_classified_listings).with(listing)
      end
    end

    describe "when no listing is found" do
      it "does not error" do
        expect { described_class.perform_now(nil, cache_buster) }.not_to raise_error
      end

      it "does not bust cache" do
        described_class.perform_now(nil, cache_buster)
        expect(cache_buster).not_to have_received(:bust_classified_listings)
      end
    end
  end
end
