require "rails_helper"

# rubocop:disable RSpec/NestedGroups

RSpec.describe "Api::V1::Organizations" do
  let(:headers) { { "Accept" => "application/vnd.forem.api-v1+json" } }

  describe "admin-only endpoints" do
    let!(:org_params) do
      {
        name: "Test Org",
        summary: "a test org",
        url: "https://testorg.io",
        profile_image: "https://dummyimage.com/400x400.png",
        slug: "test-org",
        tag_line: "a tagline"
      }
    end

    context "when unauthorized and requesting from an admin-only endpoint" do
      let(:organization) { create(:organization) }

      it "rejects requests without an authorization token" do
        expect do
          put api_organization_path(organization.id), params: { organization: org_params }, headers: headers
        end.not_to change(User, :count)

        expect(response).to have_http_status(:unauthorized)
      end

      it "rejects requests with a non-admin token" do
        api_secret = create(:api_secret, user: create(:user))
        admin_headers = headers.merge({ "api-key" => api_secret.secret })

        expect do
          put api_organization_path(organization.id),
              params: { organization: org_params.merge({ summary: "new summary" }) },
              headers: admin_headers
        end.not_to change(organization, :summary)

        expect(response).to have_http_status(:unauthorized)
      end

      it "rejects delete requests with a regular admin token" do
        api_secret = create(:api_secret, user: create(:user, :admin))
        admin_headers = headers.merge({ "api-key" => api_secret.secret })

        expect do
          delete api_organization_path(organization.id), headers: admin_headers
        end.not_to change(User, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    describe "POST /api/organizations" do
      let!(:user) { create(:user, :super_admin) }
      let(:api_secret) { create(:api_secret, user: user) }
      let(:admin_headers) { headers.merge({ "api-key" => api_secret.secret }) }

      context "when user has site admin privileges and params are valid" do
        before do
          # mock around the remote image url retreival and upload
          profile_image = Images::ProfileImageGenerator.call
          organization = Organization.new(org_params.merge(profile_image: profile_image))
          # Organizations#create controller takes the image param as "profile_image".. if it's not a file,
          # the controller sets the remote_profile_image_url instead
          profile_image_url = org_params[:profile_image]
          allow(Organization).to receive(:new).and_return(organization)
          allow(organization).to receive(:profile_image).and_return(profile_image)
          allow(organization).to receive(:profile_image_url).and_return(profile_image_url)
        end

        it "accepts request and creates the organization" do
          expect do
            post api_organizations_path, params: { organization: org_params }, headers: admin_headers
          end.to change(Organization, :count).by(1)

          expect(response).to have_http_status(:created)
        end
      end

      context "when user does not have site-admin-level privileges" do
        let!(:user) { create(:user, :admin) }
        let(:api_secret) { create(:api_secret, user: user) }
        let(:admin_headers) { headers.merge({ "api-key" => api_secret.secret }) }

        it "returns a 401 and does not create the organization" do
          expect do
            post api_organizations_path, params: { organization: org_params }, headers: admin_headers
          end.not_to change(Organization, :count)

          expect(response).to have_http_status(:unauthorized)
        end
      end

      context "when params are invalid" do
        it "returns a 422 and does not create the organization" do
          expect do
            post api_organizations_path, params: {}, headers: admin_headers
          end.not_to change(Organization, :count)

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    describe "PUT /api/organizations/:id" do
      let!(:org_admin) { create(:user, :org_admin, :admin) }
      let(:api_secret) { create(:api_secret, user: org_admin) }
      let!(:organization) { org_admin.organizations.first }
      let(:admin_headers) { headers.merge({ "api-key" => api_secret.secret }) }

      it "accepts request and updates the organization with valid params" do
        expect do
          put api_organization_path(organization.id), headers: admin_headers, params: {
            organization: { summary: "new summary" }
          }
        end.to change { organization.reload.summary }.to("new summary")

        expect(response).to have_http_status(:ok)
      end

      it "returns a 422 and does not update the organization with invalid params" do
        expect do
          put api_organization_path(organization.id),
              params: { organization: { slug: "" } },
              headers: admin_headers
        end.not_to change(organization, :name)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe "DELETE /api/organizations/:id" do
      context "when the user is a super admin" do
        let!(:super_admin) { create(:user, :org_admin, :super_admin) }
        let(:super_api_secret) { create(:api_secret, user: super_admin) }
        let!(:organization) { super_admin.organizations.first }
        let(:super_admin_headers) { headers.merge({ "api-key" => super_api_secret.secret }) }

        it "accepts request and schedules the organization for deletion when found" do
          expect do
            delete api_organization_path(organization.id), headers: super_admin_headers
          end.not_to change(Organization, :count)

          expect(response).to have_http_status(:ok)
          expect(response.parsed_body["message"]).to eq(
            "deletion scheduled for organization with ID #{organization.id}",
          )
        end

        it "errors if no organization is found" do
          expect do
            delete api_organization_path(0), headers: super_admin_headers
          end.not_to change(Organization, :count)

          expect(response).to have_http_status(:not_found)
        end
      end

      context "when the user is not a super admin" do
        let!(:org_admin) { create(:user, :org_admin, :admin) }
        let(:api_secret) { create(:api_secret, user: org_admin) }
        let(:admin_headers) { headers.merge({ "api-key" => api_secret.secret }) }
        let!(:organization) { org_admin.organizations.first }

        it "responds with an error" do
          expect do
            delete api_organization_path(organization.id), headers: admin_headers
          end.not_to change(Organization, :count)

          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
  end

  describe "GET /api/organizations" do
    before { create(:organization) }

    it "retrieves all organizations and renders the collection as json" do
      get api_organizations_path, headers: headers
      expect(response).to have_http_status(:success)
      expect(response.parsed_body.size).to eq(1)
      expect(response.parsed_body.first.keys).to match_array(%w[id name profile_image slug summary tag_line url])
    end
  end

  describe "GET /api/organizations/:id" do
    let(:organization) { create(:organization) }

    it "returns the correct json representation of the organization", :aggregate_failures do
      get api_organization_path(organization.id), headers: headers
      response_organization = response.parsed_body
      expect(response_organization).to include(
        {
          "name" => organization.name,
          "summary" => organization.summary,
          "profile_image" => organization.profile_image_url,
          "url" => organization.url,
          "username" => organization.slug
        },
      )

      %w[
        id username name summary twitter_username github_username url location tech_stack tag_line story
      ].each do |attr|
        expect(response_organization[attr]).to eq(organization.public_send(attr))
      end
    end

    it "returns 404 if the organizations id is not found" do
      get "/api/organizations/0", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/organizations/:username" do
    let(:organization) { create(:organization) }

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

    it "respects API_PER_PAGE_MAX limit set in ENV variable" do
      allow(ApplicationConfig).to receive(:[]).and_return(nil)
      allow(ApplicationConfig).to receive(:[]).with("APP_PROTOCOL").and_return("http://")
      allow(ApplicationConfig).to receive(:[]).with("API_PER_PAGE_MAX").and_return(2)

      create(:organization_membership, user: create(:user), organization: organization)
      create(:organization_membership, user: create(:user), organization: organization)
      create(:organization_membership, user: create(:user), organization: organization)

      get api_organization_users_path(organization.username), params: { per_page: 10 }
      expect(response.parsed_body.count).to eq(2)
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

      expect(response_org_users.key?("email")).to be false
    end
  end

  describe "GET /api/organizations/:username/listings" do
    let(:org_user) { create(:user, :org_member) }
    let(:organization) { org_user.organizations.first }
    let!(:listing) { create(:listing, user: org_user, organization: organization) }

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

    it "respects API_PER_PAGE_MAX limit set in ENV variable" do
      allow(ApplicationConfig).to receive(:[]).and_return(nil)
      allow(ApplicationConfig).to receive(:[]).with("APP_PROTOCOL").and_return("http://")
      allow(ApplicationConfig).to receive(:[]).with("API_PER_PAGE_MAX").and_return(2)

      create_list(:listing, 3, user: org_user, organization: organization)

      get api_organization_listings_path(organization.username), params: { per_page: 10 }, headers: headers
      expect(response.parsed_body.count).to eq(2)
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

    it "respects API_PER_PAGE_MAX limit set in ENV variable" do
      allow(ApplicationConfig).to receive(:[]).and_return(nil)
      allow(ApplicationConfig).to receive(:[]).with("APP_PROTOCOL").and_return("http://")
      allow(ApplicationConfig).to receive(:[]).with("API_PER_PAGE_MAX").and_return(2)

      create_list(:article, 3, organization: organization)

      get api_organization_articles_path(organization.username), params: { per_page: 10 }, headers: headers
      expect(response.parsed_body.count).to eq(2)
    end
  end
end

# rubocop:enable RSpec/NestedGroups
