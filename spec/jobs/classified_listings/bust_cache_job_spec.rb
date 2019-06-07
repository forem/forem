require "rails_helper"

RSpec.describe ClassifiedListings::BustCacheJob, type: :job do
  include_examples "#enqueues_job", "classified_listings_bust_cache", 789

  describe "#perform_now" do
    let(:user) { create(:user) }
    let!(:classified_listing) { FactoryBot.create(:classified_listing, user_id: user.id) }
    let(:cache_buster) { double }

    before do
      allow(cache_buster).to receive(:bust_classified_listings)
    end

    describe "when no listing is found" do
      it "doest not call the service" do
        allow(ClassifiedListing).to receive(:find_by).and_return(nil)
        described_class.perform_now(789, cache_buster)
        expect(cache_buster).not_to have_received(:bust_classified_listings)
      end
    end

    it "busts cache" do
      described_class.perform_now(classified_listing.id, cache_buster)
      expect(cache_buster).to have_received(:bust_classified_listings).with(classified_listing)
    end
  end
end
