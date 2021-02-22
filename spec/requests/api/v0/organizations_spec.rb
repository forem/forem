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
      expect(response_organization).to include(
        {
          "profile_image" => organization.profile_image_url,
          "type_of" => "organization",
          "joined_at" => organization.created_at.utc.iso8601
        },
      )

      %w[
        username name summary twitter_username github_username url location tech_stack tag_line story
      ].each do |attr|
        expect(response_organization[attr]).to eq(organization.public_send(attr))
      end
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

  describe "GET /api/organizations/:username/articles" do
    let(:org_user) { create(:user, :org_member) }
    let(:organization) { org_user.organizations.first }
    let!(:article) { create(:article, user: org_user, organization: organization) }

    it "returns 404 if the organizations articles is not found" do
      get "/api/organizations/invalid-username/articles"
      expect(response).to have_http_status(:not_found)
    end

    it "supports pagination" do
      create(:article, organization: organization)

      get api_organization_articles_path(organization.username), params: { page: 1, per_page: 1 }
      expect(response.parsed_body.length).to eq(1)

      get api_organization_articles_path(organization.username), params: { page: 2, per_page: 1 }
      expect(response.parsed_body.length).to eq(1)

      get api_organization_articles_path(organization.username), params: { page: 3, per_page: 1 }
      expect(response.parsed_body.length).to eq(0)
    end

    it "returns the correct json representation of the organizations articles", :aggregate_failures do
      get api_organization_articles_path(organization.username)
      response_article = response.parsed_body.first
      expect(response_article["type_of"]).to eq("article")

      %w[id title slug description path public_reactions_count
         positive_reactions_count comments_count published_timestamp].each do |attr|
        expect(response_article[attr]).to eq(article.public_send(attr))
      end

      expect(response_article["tag_list"]).to match_array(article.tag_list)

      %w[name username twitter_username github_username website_url].each do |attr|
        expect(response_article["user"][attr]).to eq(org_user.public_send(attr))
      end

      %w[name username slug].each do |attr|
        expect(response_article["organization"][attr]).to eq(organization.public_send(attr))
      end
    end
  end

  describe "GET /api/organizations/:username/status(/:status)" do
    context "when request is unauthenticated" do
      let(:user) { create(:user) }
      let(:public_token) { create :doorkeeper_access_token, resource_owner: user, scopes: "public" }

      it "return unauthorized" do
        get api_organization_status_path
        expect(response).to have_http_status(:unauthorized)
      end

      it "returns forbidden when requesting for all with only public scope" do
        get api_organization_status_path(status: :all), params: { access_token: public_token.token }
        expect(response).to have_http_status(:forbidden)
      end

      it "returns forbidden status when requesting unpublished with public scope" do
        get api_organization_status_path(status: :unpublished), params: { access_token: public_token.token }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when request is authenticated" do
      let(:user) { create(:user) }
      let(:access_token) { create :doorkeeper_access_token, resource_owner: user, scopes: "public read_articles" }
      let(:org_user) { create(:user, :org_member) }
      let(:organization) { org_user.organizations.first }
      let!(:article) { create(:article, user: org_user, organization: organization) }

      it "works with bearer authorization" do
        headers = { "authorization" => "Bearer #{access_token.token}", "content-type" => "application/json" }

        get api_organization_status_path, headers: headers
        expect(response.media_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
      end

      it "returns proper response specification" do
        get api_organization_status_path, params: { access_token: access_token.token }
        expect(response.media_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
      end

      it "returns success when requesting published articles with public token" do
        public_token = create(:doorkeeper_access_token, resource_owner: user, scopes: "public")
        get api_organization_status_path(status: :published), params: { access_token: public_token.token }
        expect(response.media_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
      end

      it "return only orgs's articles including markdown" do
        create(:article, organization: organization)

        get api_organization_status_path, params: { access_token: access_token.token }
        expect(response.parsed_body.length).to eq(1)
        expect(response.parsed_body[0]["body_markdown"]).not_to be_nil
      end

      it "only includes published articles by default" do
        create(:article, published: false, published_at: nil, organization: organization)
        get api_organization_status_path, params: { access_token: access_token.token }
        expect(response.parsed_body.length).to eq(0)
      end

      it "only includes published articles when asking for published articles" do
        create(:article, published: false, published_at: nil, organization: organization)
        get me_api_articles_path(status: :published), params: { access_token: access_token.token }
        expect(response.parsed_body.length).to eq(0)
      end

      it "only includes unpublished articles when asking for unpublished articles" do
        create(:article, published: false, published_at: nil, organization: organization)
        get me_api_articles_path(status: :unpublished), params: { access_token: access_token.token }
        expect(response.parsed_body.length).to eq(1)
      end

      it "orders unpublished articles by reverse order when asking for unpublished articles" do
        older = create(:article, published: false, published_at: nil, organization: organization)
        newer = nil
        Timecop.travel(1.day.from_now) do
          newer = create(:article, published: false, published_at: nil, organization: organization)
        end
        get me_api_articles_path(status: :unpublished), params: { access_token: access_token.token }
        expected_order = response.parsed_body.map { |resp| resp["id"] }
        expect(expected_order).to eq([newer.id, older.id])
      end

      it "puts unpublished articles at the top when asking for all articles" do
        create(:article, organization: organization)
        create(:article, published: false, published_at: nil,organization: organization)
        get me_api_articles_path(status: :all), params: { access_token: access_token.token }
        expected_order = response.parsed_body.map { |resp| resp["published"] }
        expect(expected_order).to eq([false, true])
      end
    end
  end
end
