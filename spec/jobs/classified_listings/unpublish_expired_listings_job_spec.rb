require "rails_helper"

RSpec.describe ClassifiedListings::UnpublishExpiredListingsJob, type: :job do
  include_examples "#enqueues_job", "classified_listings_unpublish_expired"

  describe "#perform_now" do
    let(:user) { create(:user) }
    let(:classified_listing) { FactoryBot.create(:classified_listing, user_id: user.id) }
    let(:future_expired_listing) { FactoryBot.create(:classified_listing, user_id: user.id, expire_on: Date.tomorrow) }
    let!(:expired_listing) { FactoryBot.create(:classified_listing, user_id: user.id, expire_on: Date.tomorrow) }

    describe "when no listings are found" do
      it "doesn't change anything with listings" do
        expect do
          described_class.perform_now
        end.not_to change(ClassifiedListing.where(published: true), :count)
      end
    end

    it "unpublishes expired listings" do
      expired_listing.expire_on = Date.today
      expired_listing.save
      expect do
        described_class.perform_now
      end.to change(expired_listing, :published)
    end
  end
end
