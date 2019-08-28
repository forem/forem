require "rails_helper"

RSpec.describe "/internal/listings", type: :request do
  describe "PUT /internal/listings/:id" do
    let(:admin) { create(:user, :super_admin) }
    let(:classified_listing) { create(:classified_listing, user_id: admin.id) }
    let(:cache_buster) { instance_double(CacheBuster) }

    before do
      allow(CacheBuster).to receive(:new).and_return(cache_buster)
      allow(cache_buster).to receive(:bust_classified_listings)
      sign_in admin
    end

    it "clears listing cache" do
      put "/internal/listings/#{classified_listing.id}", params: {
        classified_listing: { title: "updated" }
      }
      expect(cache_buster).to have_received(:bust_classified_listings)
    end
  end
end
