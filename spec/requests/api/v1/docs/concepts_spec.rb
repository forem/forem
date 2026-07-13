require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName
# rubocop:disable Layout/LineLength

RSpec.describe "Api::V1::Docs::Concepts" do
  let(:Accept) { "application/vnd.forem.api-v1+json" }
  let(:admin) { create(:user, :super_admin) }
  let(:user) { create(:user) }
  let(:admin_api_secret) { create(:api_secret, user: admin) }
  let(:user_api_secret) { create(:api_secret, user: user) }
  let(:embedding) { Array.new(768, 0.1) }
  let!(:concept) { create(:concept, anchor_embedding: embedding) }

  describe "GET /concepts" do
    path "/api/concepts" do
      get "Retrieve all accessible concepts" do
        tags "concepts"
        produces "application/json"
        parameter name: :page, in: :query, required: false, schema: { type: :integer }
        parameter name: :per_page, in: :query, required: false, schema: { type: :integer }
        parameter name: :days, in: :query, required: false, schema: { type: :integer }

        response "200", "successful" do
          let(:"api-key") { admin_api_secret.secret }
          schema type: :array, items: { "$ref": "#/components/schemas/Concept" }
          add_examples
          run_test!
        end

        response "401", "unauthorized" do
          let(:"api-key") { nil }
          add_examples
          run_test!
        end
      end
    end
  end

  describe "GET /concepts/{id}" do
    path "/api/concepts/{id}" do
      get "Retrieve details of a concept" do
        tags "concepts"
        produces "application/json"
        parameter name: :id, in: :path, required: true, schema: { type: :integer }
        parameter name: :days, in: :query, required: false, schema: { type: :integer }

        response "200", "successful" do
          let(:"api-key") { admin_api_secret.secret }
          let(:id) { concept.id }
          schema "$ref": "#/components/schemas/Concept"
          add_examples
          run_test!
        end

        response "401", "unauthorized" do
          let(:"api-key") { nil }
          let(:id) { concept.id }
          add_examples
          run_test!
        end
      end
    end
  end

  describe "PATCH /concepts/{id}" do
    path "/api/concepts/{id}" do
      patch "Update a concept's metadata" do
        tags "concepts"
        consumes "application/json"
        produces "application/json"
        parameter name: :id, in: :path, required: true, schema: { type: :integer }
        parameter name: :concept_params, in: :body, schema: {
          type: :object,
          properties: {
            concept: {
              type: :object,
              properties: {
                score: { type: :number },
                description: { type: :string },
                similarity_threshold: { type: :number }
              }
            }
          }
        }

        before do
          allow_any_instance_of(Concepts::AnchorGenerator).to receive(:call)
          allow(Concepts::BackfillClassifierWorker).to receive(:perform_async)
        end

        response "200", "successful" do
          let(:"api-key") { admin_api_secret.secret }
          let(:id) { concept.id }
          let(:concept_params) { { concept: { score: 4.5, description: "Updated", similarity_threshold: 0.8 } } }
          schema "$ref": "#/components/schemas/Concept"
          add_examples
          run_test!
        end
      end
    end
  end

  describe "GET /concepts/{id}/articles" do
    path "/api/concepts/{id}/articles" do
      get "Retrieve articles mapped to a concept" do
        tags "concepts"
        produces "application/json"
        parameter name: :id, in: :path, required: true, schema: { type: :integer }
        parameter name: :sort, in: :query, required: false, schema: { type: :string }
        parameter name: :page, in: :query, required: false, schema: { type: :integer }
        parameter name: :per_page, in: :query, required: false, schema: { type: :integer }

        response "200", "successful" do
          let(:"api-key") { admin_api_secret.secret }
          let(:id) { concept.id }
          schema type: :array, items: { "$ref": "#/components/schemas/ArticleIndex" }
          add_examples
          run_test!
        end
      end
    end
  end

  describe "GET /admin/concepts" do
    path "/api/admin/concepts" do
      get "Retrieve all concepts (Admin)" do
        tags "concepts", "admin"
        produces "application/json"
        parameter name: :page, in: :query, required: false, schema: { type: :integer }
        parameter name: :per_page, in: :query, required: false, schema: { type: :integer }

        response "200", "successful" do
          let(:"api-key") { admin_api_secret.secret }
          schema type: :array, items: { "$ref": "#/components/schemas/Concept" }
          add_examples
          run_test!
        end
      end
    end
  end

  describe "POST /admin/concepts" do
    path "/api/admin/concepts" do
      post "Create a concept (Admin)" do
        tags "concepts", "admin"
        consumes "application/json"
        produces "application/json"
        parameter name: :concept_params, in: :body, schema: {
          type: :object,
          properties: {
            concept: {
              type: :object,
              properties: {
                name: { type: :string },
                description: { type: :string },
                parent_id: { type: :integer, nullable: true },
                similarity_threshold: { type: :number },
                score: { type: :number }
              },
              required: [:name]
            }
          }
        }

        before do
          allow_any_instance_of(Concepts::AnchorGenerator).to receive(:call) do |generator|
            concept_instance = generator.instance_variable_get(:@concept)
            concept_instance.anchor_embedding = embedding
          end
          allow(Concepts::BackfillClassifierWorker).to receive(:perform_async)
        end

        response "201", "created" do
          let(:"api-key") { admin_api_secret.secret }
          let(:concept_params) { { concept: { name: "Docs Concept", description: "Created", similarity_threshold: 0.7 } } }
          schema "$ref": "#/components/schemas/Concept"
          add_examples
          run_test!
        end
      end
    end
  end

  describe "GET /admin/concepts/{id}" do
    path "/api/admin/concepts/{id}" do
      get "Retrieve concept detail (Admin)" do
        tags "concepts", "admin"
        produces "application/json"
        parameter name: :id, in: :path, required: true, schema: { type: :integer }

        response "200", "successful" do
          let(:"api-key") { admin_api_secret.secret }
          let(:id) { concept.id }
          schema "$ref": "#/components/schemas/Concept"
          add_examples
          run_test!
        end
      end
    end
  end

  describe "PATCH /admin/concepts/{id}" do
    path "/api/admin/concepts/{id}" do
      patch "Update a concept (Admin)" do
        tags "concepts", "admin"
        consumes "application/json"
        produces "application/json"
        parameter name: :id, in: :path, required: true, schema: { type: :integer }
        parameter name: :concept_params, in: :body, schema: {
          type: :object,
          properties: {
            concept: {
              type: :object,
              properties: {
                name: { type: :string },
                description: { type: :string },
                parent_id: { type: :integer, nullable: true },
                similarity_threshold: { type: :number },
                score: { type: :number }
              }
            }
          }
        }

        before do
          allow_any_instance_of(Concepts::AnchorGenerator).to receive(:call)
          allow(Concepts::BackfillClassifierWorker).to receive(:perform_async)
        end

        response "200", "successful" do
          let(:"api-key") { admin_api_secret.secret }
          let(:id) { concept.id }
          let(:concept_params) { { concept: { name: "Updated Admin Concept" } } }
          schema "$ref": "#/components/schemas/Concept"
          add_examples
          run_test!
        end
      end
    end
  end

  describe "DELETE /admin/concepts/{id}" do
    path "/api/admin/concepts/{id}" do
      delete "Delete a concept (Admin)" do
        tags "concepts", "admin"
        produces "application/json"
        parameter name: :id, in: :path, required: true, schema: { type: :integer }

        response "204", "no content" do
          let(:"api-key") { admin_api_secret.secret }
          let(:id) { concept.id }
          add_examples
          run_test!
        end
      end
    end
  end

  describe "POST /admin/concepts/{id}/trigger_lookback" do
    path "/api/admin/concepts/{id}/trigger_lookback" do
      post "Trigger concept lookback backfill (Admin)" do
        tags "concepts", "admin"
        consumes "application/json"
        produces "application/json"
        parameter name: :id, in: :path, required: true, schema: { type: :integer }
        parameter name: :lookback_params, in: :body, schema: {
          type: :object,
          properties: {
            days: { type: :integer }
          },
          required: [:days]
        }

        before do
          allow(Concepts::LookbackWorker).to receive(:perform_async)
        end

        response "200", "successful" do
          let(:"api-key") { admin_api_secret.secret }
          let(:id) { concept.id }
          let(:lookback_params) { { days: 10 } }
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
