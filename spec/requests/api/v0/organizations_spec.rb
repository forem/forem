require "rails_helper"

RSpec.describe "Api::V0::Organizations" do
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
        id username name summary twitter_username github_username url location tech_stack tag_line story
      ].each do |attr|
        expect(response_organization[attr]).to eq(organization.public_send(attr))
      end
    end

    it "matches Jbuilder byte-for-byte via ForemNative", :aggregate_failures do
      organization.update!(name: "Forem <Org> & Co.", summary: "Open source 🚀")

      native_results = []
      allow(ForemNative).to receive(:serialize_api_organization_json).and_wrap_original do |method, *args|
        method.call(*args).tap { |res| native_results << res }
      end

      get api_organization_path(organization.username)
      native_body = response.body
      expect(native_results.length).to eq(1)
      expect(native_results.first).to be_a(String)

      allow(ForemNative).to receive(:serialize_api_organization_json).and_return(nil)
      get api_organization_path(organization.username)
      expect(native_body).to eq(response.body)
    end

    it "skips native serialization when HTML entity escaping is disabled" do
      allow(ActiveSupport::JSON::Encoding).to receive(:escape_html_entities_in_json).and_return(false)
      allow(ForemNative).to receive(:serialize_api_organization_json).and_call_original

      get api_organization_path(organization.username)

      expect(response).to have_http_status(:ok)
      expect(ForemNative).not_to have_received(:serialize_api_organization_json)
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
      get api_organization_users_path(organization.username)

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

    it "does not execute N+1 queries on profiles when serializing organization users" do
      create(:organization_membership, user: create(:user), organization: organization)
      create(:organization_membership, user: create(:user), organization: organization)

      queries = []
      callback = ->(_name, _start, _finish, _id, payload) { queries << payload[:sql] unless payload[:name] == "SCHEMA" }

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        get api_organization_users_path(organization.username)
      end

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(3)
      expect(queries.grep(/FROM "profiles"/i)).to be_empty
    end

    it "matches Jbuilder byte-for-byte via ForemNative under UTC", :aggregate_failures do
      org_user.update!(name: "Ada <Org> & Co.", created_at: Time.utc(2026, 1, 5, 8, 30, 0))
      create(:organization_membership, user: create(:user, name: "Bob 🚀"), organization: organization)

      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("TZ").and_return("Etc/UTC")

      Time.use_zone("UTC") do
        native_results = []
        allow(ForemNative).to receive(:serialize_api_users_json).and_wrap_original do |method, *args|
          method.call(*args).tap { |res| native_results << res }
        end

        get api_organization_users_path(organization.username)
        native_body = response.body
        expect(native_results.length).to eq(1)
        expect(native_results.first).to be_a(String)

        allow(ForemNative).to receive(:serialize_api_users_json).and_return(nil)
        fallback_queries = []
        callback = lambda do |_name, _start, _finish, _id, payload|
          fallback_queries << payload[:sql] unless payload[:name] == "SCHEMA"
        end

        ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
          get api_organization_users_path(organization.username)
        end

        expect(native_body).to eq(response.body)
        expect(fallback_queries.grep(/FROM "profiles"/i)).to be_empty
      end
    end
  end

  describe "GET /api/organizations/:username/listings" do
    let(:organization) { create(:organization) }

    it "returns 404 if the organization is not found" do
      get "/api/organizations/invalid-username/listings"
      expect(response).to have_http_status(:not_found)
    end

    it "returns an empty array since listings have been removed" do
      get "/api/organizations/#{organization.username}/listings"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq([])
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

      get api_organization_articles_path(organization.username), params: { per_page: 10 }
      expect(response.parsed_body.count).to eq(2)
    end
  end
end
