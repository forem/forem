require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName

RSpec.describe "Api::V1::Docs::Organizations" do
  let(:Accept) { "application/vnd.forem.api-v1+json" }
  let(:organization) { create(:organization) }

  describe "GET /api/organizations/{username}" do
    before do
      create_list(:user, 2).map do |user|
        create(:organization_membership, user: user, organization: organization)
      end
      create(:article, organization: organization)
    end

    path "/api/organizations/{username}" do
      get "An organization (by username)" do
        tags "organizations"
        security []
        description "This endpoint allows the client to retrieve a single organization by their username"
        operationId "getOrganization"
        produces "application/json"
        parameter name: :username, in: :path, type: :string, required: true

        response "200", "An Organization" do
          let(:username) { organization.username }
          schema  type: :object,
                  items: { "$ref": "#/components/schemas/Organization" }
          add_examples
          run_test!
        end

        response "404", "Not Found" do
          let(:username) { "non-existent-username" }
          add_examples
          run_test!
        end
      end
    end

    path "/api/organizations/{username}/users" do
      get "Organization's users" do
        tags "organizations", "users"
        security []
        description "This endpoint allows the client to retrieve a list of users belonging to the organization

It supports pagination, each page will contain `30` users by default."
        operationId "getOrgUsers"
        produces "application/json"
        parameter name: :username, in: :path, type: :string, required: true
        parameter "$ref": "#/components/parameters/pageParam"
        parameter "$ref": "#/components/parameters/perPageParam30to1000"

        response "200", "An Organization's users" do
          let(:username) { organization.username }
          schema  type: :array,
                  items: { "$ref": "#/components/schemas/User" }
          add_examples
          run_test!
        end

        response "404", "Not Found" do
          let(:username) { "non-existent-username" }
          add_examples
          run_test!
        end
      end
    end

    path "/api/organizations/{username}/articles" do
      get "Organization's Articles" do
        tags "organizations", "articles"
        security []
        description "This endpoint allows the client to retrieve a list of Articles belonging to the organization

It supports pagination, each page will contain `30` users by default."
        operationId "getOrgArticles"
        produces "application/json"
        parameter name: :username, in: :path, type: :string, required: true
        parameter "$ref": "#/components/parameters/pageParam"
        parameter "$ref": "#/components/parameters/perPageParam30to1000"

        response "200", "An Organization's Articles" do
          let(:username) { organization.username }
          schema  type: :array,
                  items: { "$ref": "#/components/schemas/ArticleIndex" }
          add_examples
          run_test!
        end

        response "404", "Not Found" do
          let(:username) { "non-existent-username" }
          add_examples
          run_test!
        end
      end
    end
  end

  describe "GET /api/organizations" do
    before do
      create(:organization)
    end

    path "/api/organizations" do
      get "Organizations" do
        tags "organizations"
        security []
        description "This endpoint allows the client to retrieve a list of Dev organizations.

  It supports pagination, each page will contain 10 tags by default."
        operationId "getOrganizations"
        produces "application/json"
        parameter "$ref": "#/components/parameters/pageParam"
        parameter "$ref": "#/components/parameters/perPageParam10to1000"

        response "200", "A list of all organizations" do
          schema  type: :array,
                  items: { "$ref": "#/components/schemas/Organization" }
          add_examples

          run_test!
        end
      end
    end
  end

  describe "GET /api/organizations/{id}" do
    let!(:organization) { create(:organization) }

    path "/api/organizations/{id}" do
      get "An organization (by id)" do
        tags "organizations"
        security []
        description "This endpoint allows the client to retrieve a single organization by their id"
        operationId "getOrganizationById"
        produces "application/json"
        parameter name: :id, in: :path, type: :integer, required: true

        response "200", "An Organization" do
          let(:id) { organization.id }
          schema type: :object,
                 items: { "$ref": "#/components/schemas/Organization" }
          add_examples

          run_test!
        end

        response "404", "Not Found" do
          let(:id) { 0 }
          add_examples

          run_test!
        end
      end
    end
  end

  describe "POST /api/organizations" do
    let(:api_secret) { create(:api_secret, user: create(:user, :super_admin)) }
    let(:image_url) { "https://dummyimage.com/400x400.jpg" }
    let(:org_params) do
      {
        name: "New Test Org",
        summary: "a newly created test org",
        url: "https://testorg.io",
        profile_image: image_url,
        slug: "org10001",
        tag_line: "a test org's tagline"
      }
    end

    before do
      # mocking out the process where carrierwave takes the image at the url and uploads
      stub_request(:get, "https://dummyimage.com").to_return(body: "", status: 200)
      organization = Organization.new(org_params)
      allow(Organization).to receive(:new).and_return(organization)
      allow(organization).to receive(:profile_image_url).and_return("uploads/organization/profile_image/1/400x400.jpg")
      uploaded_image_mock = Rails.root.join("app/assets/images/2.png").open
      allow(organization).to receive(:profile_image).and_return(uploaded_image_mock)
    end

    path "/api/organizations" do
      post "Create an Organization" do
        tags "organizations"
        description "This endpoint allows the client to create an organization with the provided parameters.

        It requires a token from a user with `admin` privileges."
        operationId "createOrganization"
        produces "application/json"
        consumes "application/json"
        parameter name: :organization,
                  in: :body,
                  description: "Representation of Organization to be created",
                  schema: { "$ref": "#/components/schemas/Organization" }

        response "201", "Successful" do
          let(:"api-key") { api_secret.secret }
          let(:organization) do
            {
              organization: {
                name: "New Test Org",
                summary: "a newly created test org",
                url: "https://testorg.io",
                profile_image: image_url,
                slug: "org10001",
                tag_line: "a test org's tagline"
              }
            }
          end
          add_examples
          run_test!
        end

        response "401", "Unauthorized" do
          let(:regular_user) { create(:user) }
          let(:low_security_api_secret) { create(:api_secret, user: regular_user) }
          let(:"api-key") { low_security_api_secret.secret }
          let(:organization) { {} }
          examples
          run_test!
        end

        response "422", "Unprocessable Entity" do
          let(:"api-key") { api_secret.secret }
          let(:organization) { {} }
          add_examples
          run_test!
        end
      end
    end
  end

  describe "PUT /api/organizations/{id}" do
    let!(:org_admin) { create(:user, :org_admin, :admin) }
    let(:api_secret) { create(:api_secret, user: org_admin) }
    let!(:org_to_update) { org_admin.organizations.first }

    path "/api/organizations/{id}" do
      put "Update an organization by id" do
        tags "organizations"
        description "This endpoint allows an admin user to update an existing organization."
        operationId "updateOrganization"
        produces "application/json"
        consumes "application/json"
        parameter name: :id,
                  in: :path,
                  required: true,
                  description: "The ID of the organization to update.",
                  schema: {
                    type: :integer,
                    format: :int32,
                    minimum: 1
                  },
                  example: 123
        parameter name: :organization,
                  in: :body,
                  description: "Representation of Organization to be updated",
                  schema: { "$ref": "#/components/schemas/Organization" }

        response "200", "An Organization" do
          let(:"api-key") { api_secret.secret }
          let(:id) { org_to_update.id }
          let(:organization) { { organization: { summary: "An updated summary for the organization." } } }
          add_examples

          run_test!
        end

        response "404", "organization Not Found" do
          let(:"api-key") { api_secret.secret }
          let(:id) { 1_234_567_890 }
          let(:organization) { org_to_update.assign_attributes(name: "this won't update, unfindable id") }
          add_examples

          run_test!
        end

        response "401", "Unauthorized" do
          let!(:org_admin) { create(:user, :org_member) }
          let(:"api-key") { api_secret.secret }
          let(:id) { org_to_update.id }
          let(:organization) { org_to_update.assign_attributes(summary: "won't update, non-admin user privileges") }

          add_examples

          run_test!
        end

        response "422", "Unprocessable Entity" do
          let(:"api-key") { api_secret.secret }
          let(:id) { org_to_update.id }
          let(:organization) { { profile_image: "" } }
          add_examples

          run_test!
        end
      end
    end
  end

  describe "DELETE /api/organizations/{id}" do
    let!(:org_admin) { create(:user, :org_admin, :super_admin) }
    let(:api_secret) { create(:api_secret, user: org_admin) }
    let!(:org_to_delete) { org_admin.organizations.first }

    path "/api/organizations/{id}" do
      delete "Delete an Organization by id" do
        tags "organizations"
        description "This endpoint allows an admin user to schedule deletion of an organization"
        operationId "deleteOrganization"
        produces "application/json"
        parameter name: :id, in: :path, required: true,
                  description: "The ID of the organization.",
                  schema: {
                    type: :integer,
                    format: :int32,
                    minimum: 1
                  },
                  example: 1

        let(:id) { org_to_delete.id }

        response(200, "successful") do
          let(:"api-key") { api_secret.secret }
          schema "$ref": "#/components/schemas/Organization"
          add_examples

          run_test!
        end

        response "401", "unauthorized" do
          let(:"api-key") { "invalid" }
          add_examples

          run_test!
        end
      end
    end
  end
end

# rubocop:enable RSpec/EmptyExampleGroup
# rubocop:enable RSpec/VariableName
