require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup

RSpec.describe "Api::V1::Docs::Articles" do
  let(:organization) { create(:organization) }

  describe "GET /organizations/{username}" do
    before do
      create_list(:user, 2).map do |user|
        create(:organization_membership, user: user, organization: organization)
      end
      create(:article, organization: organization)
    end

    path "/api/organizations/{username}" do
      get "An organization" do
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
end

# rubocop:enable RSpec/EmptyExampleGroup
