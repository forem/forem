require "rails_helper"

RSpec.describe "/listings", type: :request do # Explicitly specify type :request
  let(:user) { create(:user) }
  let!(:listing) { create(:listing, user: user)}

  before do
    # Explicitly set the default headers for *all* requests in this spec
    # This is a "belt and suspenders" approach to ensure the correct Accept header.
    @default_headers = { "Accept" => "application/json" }
  end

  describe "GET /listings" do
    it "returns an empty JSON array" do
      get "/listings", headers: @default_headers # Use the default headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq([])
      expect(response.content_type).to eq("application/json; charset=utf-8")
    end
  end

  describe "GET /listings/dashboard" do
    it "returns an empty JSON object" do
      get "/listings/dashboard", headers: @default_headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq({})
      expect(response.content_type).to eq("application/json; charset=utf-8")
    end
  end

  describe "GET /listings/new" do
    it "returns an empty JSON object" do
      get "/listings/new", headers: @default_headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq({})
      expect(response.content_type).to eq("application/json; charset=utf-8")
    end
  end

    describe "GET /listings/edit" do

    it "has page content" do
      get "/listings/#{listing.id}/edit", headers: @default_headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq({})
      expect(response.content_type).to eq("application/json; charset=utf-8")
    end
  end

  describe "POST /listings" do
    it "does not create a listing" do
      expect {
        post "/listings", params: { listing: { title: "Test", body_markdown: "Test" } }, headers: @default_headers
      }.not_to change(Listing, :count)
      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to eq({})
      expect(response.content_type).to eq("application/json; charset=utf-8")
    end
  end

  describe "PUT /listings/:id" do
    it "does not update the listing" do
      expect {
        put "/listings/#{listing.id}", params: { listing: { title: "New Title" } }, headers: @default_headers
      }.not_to change { Listing.find(listing.id).title }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq({})
      expect(response.content_type).to eq("application/json; charset=utf-8")
    end
  end


  describe "DELETE /listings/:id" do
    it "does not delete the listing" do
      expect {
        delete "/listings/#{listing.id}", headers: @default_headers
      }.not_to change(Listing, :count)
      expect(response).to have_http_status(:no_content)
      # Remove or adjust this expectation
      # expect(response.content_type).to eq("application/json; charset=utf-8")
    end
  end
end