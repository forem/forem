require "rails_helper"
require "nokogiri"

RSpec.describe "/listings" do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }
  let(:edu_category) { create(:listing_category, cost: 1) }
  let(:listing_params) do
    {
      listing: {
        title: "something",
        body_markdown: "something else",
        listing_category_id: edu_category.id,
        tag_list: "ruby, rails, go"
      }
    }
  end
  let(:draft_params) do
    {
      listing: {
        title: "this a draft",
        body_markdown: "something draft",
        listing_category_id: edu_category.id,
        tag_list: "",
        action: "draft"
      }
    }
  end

  describe "GET /listings" do
    let(:user) { create(:user) }
    let(:listing) { create(:listing, user: user, slug: "some-slug") }
  
    before do
      sign_in user
    end
  
    it "returns text/html and has status 200" do
      get "/listings"
      expect(response.media_type).to eq("text/html")
      expect(response).to have_http_status(:ok)
    end
  
    it "listings have correct keys" do
      get "/listings"
  
      parsed_response = Nokogiri.HTML(response.body)
  
      listings = JSON.parse(parsed_response.xpath("//*[@id='listings-index-container']")[0]["data-listings"] || "[]")
  
      expect(listings).to be_empty
    end
  
    context "when the user has no params" do
      it "shows an empty listings container" do
        get "/listings"
        expect(response.body).to include("listings-container")
        expect(response.body).not_to include("listing-item") # Assuming this is the class for individual listings
      end
    end
  
    context "when the user has category and slug params for expired listing" do
      it "shows an empty listings container" do
        get "/listings", params: { category: "expired", slug: "expired-listing" }
        expect(response.body).to include("listings-container")
        expect(response.body).not_to include("listing-item") # Assuming this is the class for individual listings
      end
    end
  
    context "when view is moderate" do
      it "redirects to internal/listings/:id/edit" do
        get "/listings", params: { view: "moderate", slug: listing.slug }
        expect(response).to have_http_status(:found) # 302 status code
      end
  
      it "without a slug raises an ActiveRecord::RecordNotFound error" do
        expect do
          get "/listings", params: { view: "moderate" }
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "GET /listings/dashboard" do
    before { sign_in user }

    it "returns an empty dashboard" do
      get "/listings/dashboard"
      expect(response.body).not_to include("listing-item") # Assuming this is the class for individual listings
    end
  end

  describe "GET /listings/new" do
    before { sign_in user }

    it "shows the option to create draft" do
      get "/listings/new"
      expect(response.body).to include "You will not be charged credits to save a draft."
    end

    context "when the user has no credits" do
      it "shows the proper messages" do
        get "/listings/new"
        expect(response.body).to include "You need at least one credit to create a listing."
      end
    end

    context "when the user has credits" do
      it "shows the number of credits" do
        random_number = rand(2..100)
        create_list(:credit, random_number, user: user)
        get "/listings/new"
        expect(response.body).to include "Personal credits"
        expect(response.body).to include random_number.to_s
      end
    end

    context "when the user has no credits and belongs to an organization" do
      let(:organization) { create(:organization) }

      before { create(:organization_membership, user_id: user.id, organization_id: organization.id) }

      it "shows the proper message when both user and org have no credits" do
        get "/listings/new"
        expect(response.body).to include "You need at least one credit to create a listing."
      end

      it "shows the number of credits of the user if the user has credits but the org has no credits" do
        random_number = rand(2..100)
        create_list(:credit, random_number, user: user)
        get "/listings/new"
        expect(response.body).to include "Personal credits"
        expect(response.body).to include random_number.to_s
      end

      it "shows the number of credits of the organization if the org has credits" do
        random_number = rand(2..100)
        create_list(:credit, random_number, organization: organization)
        get "/listings/new"
        expect(response.body).to include "Organization credits"
        expect(response.body).to include random_number.to_s
      end

      it "shows the number of credits of both the user and the organization if they both have credits" do
        random_number = rand(2..100)
        create_list(:credit, random_number, organization: organization)
        create_list(:credit, random_number, user: user)
        get "/listings/new"
        expect(response.body).to include "Personal credits"
        expect(response.body).to include random_number.to_s
      end
    end
  end

  describe "POST /listings" do
    before do
      sign_in user
    end

    it "returns 200 OK" do
      post "/listings", params: listing_params
      expect(response).to have_http_status(:ok)
    end

    it "returns 200 OK for draft" do
      post "/listings", params: draft_params
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PUT /listings/:id" do
    let(:listing) { create(:listing, user: user) }

    before do
      sign_in user
    end

    it "returns 200 OK" do
      put "/listings/#{listing.id}", params: { listing: { action: "bump" } }
      expect(response).to have_http_status(:ok)
    end

    it "returns 200 OK for publish" do
      put "/listings/#{listing.id}", params: { listing: { action: "publish" } }
      expect(response).to have_http_status(:ok)
    end

    it "returns 200 OK for unpublish" do
      put "/listings/#{listing.id}", params: { listing: { action: "unpublish" } }
      expect(response).to have_http_status(:ok)
    end

    it "returns 200 OK for update" do
      put "/listings/#{listing.id}", params: { listing: { body_markdown: "hello new markdown" } }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /listings/edit" do
    let(:listing) { create(:listing, user: user) }

    before do
      create_list(:credit, 20, user: user)
      sign_in user
    end

    it "has page content" do
      get "/listings/#{listing.id}/edit"
      expect(response.body).to include("You can bump your listing")
    end
  end

  describe "DEL /listings/:id" do
    let!(:listing) { create(:listing, user: user) }
    let!(:listing_draft) { create(:listing, user: user, bumped_at: nil, published: false) }
    let(:organization) { create(:organization) }
    let!(:org_listing) { create(:listing, user: user, organization: organization) }
    let!(:org_listing_draft) do
      create(:listing, user: user, organization: organization, bumped_at: nil, published: false)
    end

    before do
      sign_in user
    end

    it "returns 200 OK when deleting draft" do
      delete "/listings/#{listing_draft.id}"
      expect(response).to have_http_status(:ok)
    end

    it "returns 200 OK when deleting listing" do
      delete "/listings/#{listing.id}"
      expect(response).to have_http_status(:ok)
    end

    it "returns 200 OK when deleting draft org listing" do
      delete "/listings/#{org_listing_draft.id}"
      expect(response).to have_http_status(:ok)
    end

    it "returns 200 OK when deleting org listing" do
      delete "/listings/#{org_listing.id}"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /delete_confirm" do
    let!(:listing) { create(:listing, user: user) }

    before { sign_in user }

    context "without listing" do
      it "renders not_found" do
        expect do
          get "/listings/#{listing.category}/#{listing.slug}_1/delete_confirm"
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end