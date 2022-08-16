require "rails_helper"

RSpec.describe "Api::V1::Organizations", type: :request do
  let(:headers) { { "Accept" => "application/vnd.forem.api-v1+json" } }

  describe "GET /api/organizations/:username" do
    let(:organization) { create(:organization) }

    before { allow(FeatureFlag).to receive(:enabled?).with(:api_v1).and_return(true) }

    it "returns 404 if the organizations username is not found" do
      get "/api/organizations/invalid-username", headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it "returns the correct json representation of the organization", :aggregate_failures do
      get api_organization_path(organization.username), headers: headers

      response_organization = response.parsed_body
      expect(response_organization).to include(
        {
          "profile_image" => organization.profile_image_url,
          "type_of" => "organization",
          "joined_at" => organization.created_at.utc.iso8601
        },
      )

      %w[
        id username name summary twitter_username github_username url location tech_stack tag_line story
      ].each do |attr|
        expect(response_organization[attr]).to eq(organization.public_send(attr))
      end
    end
  end

  describe "GET /api/organizations/:username/users" do
    let!(:org_user) { create(:user, :org_member) }
    let(:organization) { org_user.organizations.first }

    before { allow(FeatureFlag).to receive(:enabled?).with(:api_v1).and_return(true) }

    it "returns 404 if the organizations username is not found" do
      get "/api/organizations/invalid-username/users", headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it "supports pagination" do
      create(:organization_membership, user: create(:user), organization: organization)

      get api_organization_users_path(organization.username), params: { page: 1, per_page: 1 }, headers: headers
      expect(response.parsed_body.length).to eq(1)

      get api_organization_users_path(organization.username), params: { page: 2, per_page: 1 }, headers: headers
      expect(response.parsed_body.length).to eq(1)

      get api_organization_users_path(organization.username), params: { page: 3, per_page: 1 }, headers: headers
      expect(response.parsed_body.length).to eq(0)
    end

    it "returns the correct json representation of the organizations users", :aggregate_failures do
      get api_organization_users_path(organization.username), headers: headers

      response_org_users = response.parsed_body.first

      expect(response_org_users["type_of"]).to eq("user")

      %w[id username name twitter_username github_username].each do |attr|
        expect(response_org_users[attr]).to eq(org_user.public_send(attr))
      end

      org_user_profile = org_user.profile
      %w[summary location website_url].each do |attr|
        expect(response_org_users[attr]).to eq(org_user_profile.public_send(attr))
      end

      expect(response_org_users["joined_at"]).to eq(org_user.created_at.strftime("%b %e, %Y"))
      expect(response_org_users["profile_image"]).to eq(org_user.profile_image_url_for(length: 320))
    end
  end

  describe "GET /api/organizations/:username/listings" do
    let(:org_user) { create(:user, :org_member) }
    let(:organization) { org_user.organizations.first }
    let!(:listing) { create(:listing, user: org_user, organization: organization) }

    before { allow(FeatureFlag).to receive(:enabled?).with(:api_v1).and_return(true) }

    it "returns 404 if the organizations username is not found" do
      get "/api/organizations/invalid-username/listings", headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it "returns success for when orgnaization username exists" do
      create(:listing, user: org_user, organization: organization)
      get "/api/organizations/#{organization.username}/listings", headers: headers
      expect(response).to have_http_status(:success)
    end

    it "supports pagination" do
      create(:listing, user: org_user, organization: organization)

      get api_organization_listings_path(organization.username), params: { page: 1, per_page: 1 }, headers: headers
      expect(response.parsed_body.length).to eq(1)

      get api_organization_listings_path(organization.username), params: { page: 2, per_page: 1 }, headers: headers
      expect(response.parsed_body.length).to eq(1)

      get api_organization_listings_path(organization.username), params: { page: 3, per_page: 1 }, headers: headers
      expect(response.parsed_body.length).to eq(0)
    end

    it "returns the correct json representation of the organizations listings", :aggregate_failures do
      get api_organization_listings_path(organization.username), headers: headers
      response_listing = response.parsed_body.first
      expect(response_listing["type_of"]).to eq("listing")

      %w[id title slug body_markdown category processed_html published listing_category_id].each do |attr|
        expect(response_listing[attr]).to eq(listing.public_send(attr))
      end

      expect(response_listing["tag_list"]).to eq(listing.cached_tag_list)
      expect(response_listing["tags"]).to match_array(listing.tag_list)

      %w[name username twitter_username github_username].each do |attr|
        expect(response_listing["user"][attr]).to eq(org_user.public_send(attr))
      end

      expect(response_listing["organization"]["website_url"]).to eq(org_user.profile.website_url)

      %w[name username slug].each do |attr|
        expect(response_listing["organization"][attr]).to eq(organization.public_send(attr))
      end
    end
  end

  describe "GET /api/organizations/:username/articles" do
    let(:org_user) { create(:user, :org_member) }
    let(:organization) { org_user.organizations.first }
    let!(:article) { create(:article, user: org_user, organization: organization) }

    before { allow(FeatureFlag).to receive(:enabled?).with(:api_v1).and_return(true) }

    it "returns 404 if the organizations articles is not found" do
      get "/api/organizations/invalid-username/articles", headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it "supports pagination" do
      create(:article, organization: organization)

      get api_organization_articles_path(organization.username),
          params: { page: 1, per_page: 1 },
          headers: headers
      expect(response.parsed_body.length).to eq(1)

      get api_organization_articles_path(organization.username),
          params: { page: 2, per_page: 1 },
          headers: headers
      expect(response.parsed_body.length).to eq(1)

      get api_organization_articles_path(organization.username),
          params: { page: 3, per_page: 1 },
          headers: headers
      expect(response.parsed_body.length).to eq(0)
    end

    it "returns the correct json representation of the organizations articles", :aggregate_failures do
      get api_organization_articles_path(organization.username), headers: headers
      response_article = response.parsed_body.first
      expect(response_article["type_of"]).to eq("article")

      %w[id title slug description path public_reactions_count
         positive_reactions_count comments_count published_timestamp].each do |attr|
        expect(response_article[attr]).to eq(article.public_send(attr))
      end

      expect(response_article["tag_list"]).to match_array(article.tag_list)

      %w[name username twitter_username github_username].each do |attr|
        expect(response_article["user"][attr]).to eq(org_user.public_send(attr))
      end

      expect(response_article["user"]["website_url"]).to eq(org_user.profile.website_url)

      %w[name username slug].each do |attr|
        expect(response_article["organization"][attr]).to eq(organization.public_send(attr))
      end
    end
  end
end
