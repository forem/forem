require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName
# rubocop:disable Layout/LineLength

RSpec.describe "Api::V1::Docs::RecommendedArticlesLists" do
  let(:Accept) { "application/vnd.forem.api-v1+json" }
  let(:admin) { create(:user, :super_admin) }
  let(:admin_api_secret) { create(:api_secret, user: admin) }
  let!(:recommended_list) { create(:recommended_articles_list, user: admin) }

  describe "GET /recommended_articles_lists" do
    path "/api/recommended_articles_lists" do
      get "Retrieve all recommended articles lists" do
        tags "recommended_articles_lists"
        produces "application/json"
        parameter name: :page, in: :query, required: false, schema: { type: :integer }
        parameter name: :search, in: :query, required: false, schema: { type: :string }

        response "200", "successful" do
          let(:"api-key") { admin_api_secret.secret }
          schema type: :array, items: { "$ref": "#/components/schemas/RecommendedArticlesList" }
          add_examples
          run_test!
        end
      end
    end
  end

  describe "POST /api/recommended_articles_lists" do
    path "/api/recommended_articles_lists" do
      post "Create or update a recommended articles list" do
        tags "recommended_articles_lists"
        consumes "application/json"
        produces "application/json"
        parameter name: :list_params, in: :body, schema: {
          type: :object,
          properties: {
            name: { type: :string },
            placement_area: { type: :string },
            expires_at: { type: :string, format: "date-time" },
            user_id: { type: :integer },
            article_ids: { type: :array, items: { type: :integer } }
          },
          required: %w[user_id placement_area]
        }

        response "201", "created" do
          let(:"api-key") { admin_api_secret.secret }
          let(:another_user) { create(:user) }
          let(:list_params) { { name: "Feed List", placement_area: "main_feed", user_id: another_user.id, article_ids: [1, 2, 3] } }
          schema "$ref": "#/components/schemas/RecommendedArticlesList"
          add_examples
          run_test!
        end
      end
    end
  end

  describe "GET /api/recommended_articles_lists/{id}" do
    path "/api/recommended_articles_lists/{id}" do
      get "Retrieve details of a recommended articles list" do
        tags "recommended_articles_lists"
        produces "application/json"
        parameter name: :id, in: :path, required: true, schema: { type: :integer }

        response "200", "successful" do
          let(:"api-key") { admin_api_secret.secret }
          let(:id) { recommended_list.id }
          schema "$ref": "#/components/schemas/RecommendedArticlesList"
          add_examples
          run_test!
        end
      end
    end
  end

  describe "PATCH /api/recommended_articles_lists/{id}" do
    path "/api/recommended_articles_lists/{id}" do
      patch "Update a recommended articles list" do
        tags "recommended_articles_lists"
        consumes "application/json"
        produces "application/json"
        parameter name: :id, in: :path, required: true, schema: { type: :integer }
        parameter name: :list_params, in: :body, schema: {
          type: :object,
          properties: {
            name: { type: :string },
            placement_area: { type: :string },
            expires_at: { type: :string, format: "date-time" },
            user_id: { type: :integer },
            article_ids: { type: :array, items: { type: :integer } }
          }
        }

        response "200", "successful" do
          let(:"api-key") { admin_api_secret.secret }
          let(:id) { recommended_list.id }
          let(:list_params) { { name: "Updated Name" } }
          schema "$ref": "#/components/schemas/RecommendedArticlesList"
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
