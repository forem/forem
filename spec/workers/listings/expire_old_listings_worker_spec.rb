require "rails_helper"

RSpec.describe Listings::ExpireOldListingsWorker, type: :worker do
  let(:worker) { subject }

  include_examples "#enqueues_on_correct_queue", "low_priority"

  describe "#perform" do
    it "expires only old listings" do
      Timecop.freeze do
        bumped_listing = create(:listing, bumped_at: 41.days.ago, published: true)
        expired_listing = create(:listing, expires_at: 2.days.ago, published: true)
        valid_listing = create(:listing, expires_at: 1.week.from_now, published: true)

        worker.perform

        expect(bumped_listing.reload.published).to eq(false)
        expect(expired_listing.reload.published).to eq(false)
        expect(valid_listing.reload.published).to eq(true)
      end
    end
  end
end
