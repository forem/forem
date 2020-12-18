require "rails_helper"

RSpec.describe "Api::V0::Organizations", type: :request do
  describe "GET /api/organizations/:username" do
    let(:organization) { create(:organization) }

    it "returns 404 if the organizations username is not found" do
      get "/api/organizations/invalid-username"
      expect(response).to have_http_status(:not_found)
    end

    it "returns the correct json representation of the organization", :aggregate_failures do
      get api_organization_path(organization.username)

      response_organization = response.parsed_body

      expect(response_organization["type_of"]).to eq("organization")

      %w[
        username name summary twitter_username github_username url location tech_stack tag_line story
      ].each do |attr|
        expect(response_organization[attr]).to eq(organization.public_send(attr))
      end

      expect(response_organization["joined_at"]).to eq(organization.created_at.utc.iso8601)
    end
  end

  describe "GET /api/organizations/:username/users" do
    let!(:org_user) { create(:user, :org_member) }
    let(:organization) { org_user.organizations.first }

    it "returns 404 if the organizations username is not found" do
      get "/api/organizations/invalid-username/users"
      expect(response).to have_http_status(:not_found)
    end

    it "supports pagination" do
      create(:organization_membership, user: create(:user), organization: organization)

      get api_organization_users_path(organization.username), params: { page: 1, per_page: 1 }
      expect(response.parsed_body.length).to eq(1)

      get api_organization_users_path(organization.username), params: { page: 2, per_page: 1 }
      expect(response.parsed_body.length).to eq(1)

      get api_organization_users_path(organization.username), params: { page: 3, per_page: 1 }
      expect(response.parsed_body.length).to eq(0)
    end

    it "returns the correct json representation of the organizations users", :aggregate_failures do
      get api_organization_users_path(organization.username)

      response_org_users = response.parsed_body.first

      expect(response_org_users["type_of"]).to eq("user")

      %w[
        id username name summary twitter_username github_username website_url location
      ].each do |attr|
        expect(response_org_users[attr]).to eq(org_user.public_send(attr))
      end

      expect(response_org_users["joined_at"]).to eq(org_user.created_at.strftime("%b %e, %Y"))
      expect(response_org_users["profile_image"]).to eq(Images::Profile.call(org_user.profile_image_url, length: 320))
    end
  end

  describe "GET /api/organizations/:username/listings" do
    let(:org_user) { create(:user, :org_member) }
    let(:organization) { org_user.organizations.first }
    let!(:listing) { create(:listing, user: org_user, organization: organization) }

    it "returns 404 if the organizations username is not found" do
      get "/api/organizations/invalid-username/listings"
      expect(response).to have_http_status(:not_found)
    end

    it "supports pagination" do
      create(:listing, user: org_user, organization: organization)

      get api_organization_listings_path(organization.username), params: { page: 1, per_page: 1 }
      expect(response.parsed_body.length).to eq(1)

      get api_organization_listings_path(organization.username), params: { page: 2, per_page: 1 }
      expect(response.parsed_body.length).to eq(1)

      get api_organization_listings_path(organization.username), params: { page: 3, per_page: 1 }
      expect(response.parsed_body.length).to eq(0)
    end

    it "returns the correct json representation of the organizations listings", :aggregate_failures do
      get api_organization_listings_path(organization.username)
      response_listing = response.parsed_body.first
      expect(response_listing["type_of"]).to eq("listing")

      %w[id title slug body_markdown category processed_html published listing_category_id].each do |attr|
        expect(response_listing[attr]).to eq(listing.public_send(attr))
      end

      expect(response_listing["tag_list"]).to eq(listing.cached_tag_list)
      expect(response_listing["tags"]).to match_array(listing.tag_list)

      %w[name username twitter_username github_username website_url].each do |attr|
        expect(response_listing["user"][attr]).to eq(org_user.public_send(attr))
      end

      %w[name username slug].each do |attr|
        expect(response_listing["organization"][attr]).to eq(organization.public_send(attr))
      end
    end
  end
end
