require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName
# rubocop:disable Layout/LineLength

RSpec.describe "Api::V1::Docs::RequestRedirects" do
  let(:Accept) { "application/vnd.forem.api-v1+json" }
  let(:admin) { create(:user, :super_admin) }
  let(:admin_api_secret) { create(:api_secret, user: admin) }
  let!(:request_redirect) { RequestRedirect.create!(original_url: "/old", destination_url: "http://new.com", request_domain: "example.com") }

  describe "GET /admin/request_redirects" do
    path "/api/admin/request_redirects" do
      get "Retrieve all request redirects (Admin)" do
        tags "request_redirects", "admin"
        produces "application/json"
        parameter name: :page, in: :query, required: false, schema: { type: :integer }
        parameter name: :per_page, in: :query, required: false, schema: { type: :integer }

        response "200", "successful" do
          let(:"api-key") { admin_api_secret.secret }
          schema type: :array, items: { "$ref": "#/components/schemas/RequestRedirect" }
          add_examples
          run_test!
        end
      end
    end
  end

  describe "POST /api/admin/request_redirects" do
    path "/api/admin/request_redirects" do
      post "Create a request redirect (Admin)" do
        tags "request_redirects", "admin"
        consumes "application/json"
        produces "application/json"
        parameter name: :redirect_params, in: :body, schema: {
          type: :object,
          properties: {
            request_redirect: {
              type: :object,
              properties: {
                original_url: { type: :string },
                destination_url: { type: :string },
                request_domain: { type: :string }
              },
              required: %w[original_url destination_url request_domain]
            }
          }
        }

        response "201", "created" do
          let(:"api-key") { admin_api_secret.secret }
          let(:redirect_params) { { request_redirect: { original_url: "/test", destination_url: "http://test.com", request_domain: "test.com" } } }
          schema "$ref": "#/components/schemas/RequestRedirect"
          add_examples
          run_test!
        end
      end
    end
  end

  describe "GET /api/admin/request_redirects/{id}" do
    path "/api/admin/request_redirects/{id}" do
      get "Retrieve a request redirect's details (Admin)" do
        tags "request_redirects", "admin"
        produces "application/json"
        parameter name: :id, in: :path, required: true, schema: { type: :integer }

        response "200", "successful" do
          let(:"api-key") { admin_api_secret.secret }
          let(:id) { request_redirect.id }
          schema "$ref": "#/components/schemas/RequestRedirect"
          add_examples
          run_test!
        end
      end
    end
  end

  describe "PATCH /api/admin/request_redirects/{id}" do
    path "/api/admin/request_redirects/{id}" do
      patch "Update a request redirect (Admin)" do
        tags "request_redirects", "admin"
        consumes "application/json"
        produces "application/json"
        parameter name: :id, in: :path, required: true, schema: { type: :integer }
        parameter name: :redirect_params, in: :body, schema: {
          type: :object,
          properties: {
            request_redirect: {
              type: :object,
              properties: {
                original_url: { type: :string },
                destination_url: { type: :string },
                request_domain: { type: :string }
              }
            }
          }
        }

        response "200", "successful" do
          let(:"api-key") { admin_api_secret.secret }
          let(:id) { request_redirect.id }
          let(:redirect_params) { { request_redirect: { original_url: "/updated-old" } } }
          schema "$ref": "#/components/schemas/RequestRedirect"
          add_examples
          run_test!
        end
      end
    end
  end

  describe "DELETE /api/admin/request_redirects/{id}" do
    path "/api/admin/request_redirects/{id}" do
      delete "Delete a request redirect (Admin)" do
        tags "request_redirects", "admin"
        produces "application/json"
        parameter name: :id, in: :path, required: true, schema: { type: :integer }

        response "204", "no content" do
          let(:"api-key") { admin_api_secret.secret }
          let(:id) { request_redirect.id }
          add_examples
          run_test!
        end
      end
    end
  end
end

# rubocop:enable RSpec/VariableName
# rubocop:enable RSpec/EmptyExampleGroup
# rubocop:enable Layout/LineLength
