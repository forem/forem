require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName

RSpec.describe "Api::V1::Docs::Organizations" do
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
    path "/api/organizations/{id}" do
      get "An organization (by id)" do
        tags "organizations"
        security []
        description "This endpoint allows the client to retrieve a single organization by their id"
        operationId "getOrganizationById"
        produces "application/json"

        response(200, "An Organization") do
          let(:id) { organization.id }
          schema type: :object,
                 items: { "$ref": "#/components/schemas/Organization" }

          run_test!
        end
      end
    end
  end

  describe "POST /api/admin/organizations" do
    before do
      let(:api_secret) { create(:api_secret) }
      let(:user) { api_secret.user }
      user.add_role(:super_admin)
    end

    path "/api/admin/organizations" do
      post "Create an Organization" do
        tags "organizations"
        description "This endpoint allows the client to create an organization with the provided parameters.

        It requires a token from a user with `super_admin` privileges."
        operationId "postAdminOrganizationsCreate"
        produces "application/json"
        consumes "application/json"
        parameter name: :organization,
                  in: :body,
                  description: "Representation of Organization to be created",
                  schema: { "$ref": "#/components/schemas/Organization" }

        response "201", "An Organization" do
          let(:"api-key") { api_secret.secret }
          let(:organization) do
            {
              name: "New Test Org",
              summary: "a newly created test org",
              url: "https://testorg.io",
              profile_image: "cloudinary/path/to/img.jpg",
              slug: "org10001",
              tag_line: "a test org's tagline"
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

  describe "PUT /api/admin/organizations/{id}" do
    before do
      let(:api_secret) { create(:api_secret) }
      let(:user) { api_secret.user }
      user.add_role(:super_admin)
    end

    path "/api/admin/organizations/{id}" do
      put "Update an organization by id" do
        tags "organizations"
        description "This endpoint allows the client to update an existing organization."
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
          let(:id) { organization.id }
          let(:organization) { { organization: { summary: "An updated summary for the organization." } } }
          add_examples

          run_test!
        end

        response "404", "organization Not Found" do
          let(:"api-key") { api_secret.secret }
          let(:id) { 1_234_567_890 }
          let(:organization) { organization.assign_attributes(name: "this won't update due to unfindable id") }
          add_examples

          run_test!
        end

        response "401", "Unauthorized" do
          let(:"api-key") { nil }
          let(:id) { organization.id }
          let(:organization) { organization.assign_attributes(summary: "this won't update due to unauthorized user") }
          add_examples

          run_test!
        end

        response "422", "Unprocessable Entity" do
          let(:"api-key") { api_secret.secret }
          let(:id) { organization.id }
          let(:organization) { {} }
          add_examples

          run_test!
        end
      end
    end
  end

  describe "DELETE /api/admin/organizations/{id}" do
    before do
      let(:api_secret) { create(:api_secret) }
      let(:user) { api_secret.user }
      user.add_role(:super_admin)
    end

    path "/api/admin/organizations/{id}" do
      delete "Delete an Organization by id" do
        tags "organizations"
        description "This endpoint allows the client to delete a single organization, specified by id"

        produces "application/json"
        parameter name: :id, in: :path, required: true,
                  description: "The ID of the organization.",
                  schema: {
                    type: :integer,
                    format: :int32,
                    minimum: 1
                  },
                  example: 1

        let(:id) { organization.id }

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
