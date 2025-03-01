require "rails_helper"

RSpec.describe "Api::V0::Listings" do
  let(:cfp_category) { create(:listing_category, :cfp) }
  let(:edu_category) { create(:listing_category) }

  shared_context "with 7 listings and 2 user" do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    before do
      create_list(:listing, 3, user: user1, listing_category: cfp_category)
      create_list(:listing, 4, user: user2, listing_category: edu_category)
    end
  end

  describe "GET /api/listings" do
    include_context "with 7 listings and 2 user"

    it "returns json response and ok status" do
      get api_listings_path
      expect(response.media_type).to eq("application/json")
      expect(response).to have_http_status(:ok)
    end

    it "returns an empty array" do
      get api_listings_path
      expect(response.parsed_body).to eq([])
    end

    it "supports pagination (still empty)" do
      get api_listings_path, params: { page: 2, per_page: 2 }
      expect(response.parsed_body).to eq([])
    end

    it "sets the correct caching headers" do
      get api_listings_path
      expect(response.headers["cache-control"]).to be_present
      expect(response.headers["x-accel-expires"]).to be_present
      expect(response.headers["surrogate-control"]).to match(/max-age/).and(match(/stale-if-error/))
    end

    it "respects API_PER_PAGE_MAX limit" do
      allow(ApplicationConfig).to receive(:[]).and_return(nil)
      allow(ApplicationConfig).to receive(:[]).with("APP_PROTOCOL").and_return("http://")
      allow(ApplicationConfig).to receive(:[]).with("API_PER_PAGE_MAX").and_return(2)
      get api_listings_path, params: { per_page: 10 }
      expect(response.parsed_body).to eq([])
    end
  end

  describe "GET /api/listings/category/:category" do
    include_context "with 7 listings and 2 user"

    it "returns an empty array for any category" do
      get api_listings_category_path("cfp")
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq([])
    end
  end

  # Removed tests for GET /api/listings/:id, POST, and PUT endpoints since listings functionality is deprecated.
end
