require "rails_helper"

RSpec.describe "/internal/listings", type: :request do
  describe "PUT /internal/listings/:id" do
    let(:admin) { create(:user, :super_admin) }
    let(:classified_listing) { create(:classified_listing, user_id: admin.id) }

    before do
      allow(CacheBuster).to receive(:bust_classified_listings)
      sign_in admin
    end

    it "clears listing cache" do
      put "/internal/listings/#{classified_listing.id}", params: {
        classified_listing: { title: "updated" }
      }
      sidekiq_perform_enqueued_jobs
      expect(CacheBuster).to have_received(:bust_classified_listings)
    end
  end
end
