require "rails_helper"

RSpec.describe "/admin/apps/listings", type: :request do
  let(:admin) { create(:user, :super_admin) }
  let!(:listing) { create(:listing, user_id: admin.id) }

  before do
    allow(EdgeCache::BustListings).to receive(:call)
    sign_in admin
  end

  describe "PUT /admin/app/listings/:id" do
    it "clears listing cache" do
      put admin_listing_path(id: listing.id), params: {
        listing: { title: "updated" }
      }
      sidekiq_perform_enqueued_jobs
      expect(EdgeCache::BustListings).to have_received(:call)
    end

    it "updates the organization ID" do
      org = create(:organization)
      put admin_listing_path(id: listing.id), params: {
        listing: { organization_id: org.id }
      }
      sidekiq_perform_enqueued_jobs
      expect(listing.reload.organization_id).to eq org.id
    end

    describe "GET /admin/app/listings" do
      let!(:unpublished_listing) { create(:listing, published: false) }

      it "shows published listings" do
        get admin_listings_path

        expect(response.body).to include(CGI.escapeHTML(listing.title))
      end

      it "filters unpublished listings by default" do
        get admin_listings_path

        expect(response.body).not_to include(CGI.escapeHTML(unpublished_listing.title))
      end

      it "includes unpublished listings when asked to" do
        get admin_listings_path, params: { include_unpublished: "1" }

        expect(response.body).to include(CGI.escapeHTML(unpublished_listing.title))
      end

      it "filters by category" do
        get admin_listings_path(filter: "misc")

        expect(response.body).not_to include(CGI.escapeHTML(listing.title))
      end
    end
  end
end
