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
        description "Retrieve all accessible concepts in the system.

### Concepts Overview:
- Concepts are semantic tags generated automatically by analyzing article text using ML embeddings (`gemini-embedding-2`), rather than explicit user tags.
- Primarily used for advanced semantic categorization, automated feeds, and interest mapping."
        produces "application/json"
        parameter name: :page, in: :query, required: false,
                  description: "Pagination page index.",
                  schema: { type: :integer }
        parameter name: :per_page, in: :query, required: false,
                  description: "Number of items to return per page.",
                  schema: { type: :integer }
        parameter name: :days, in: :query, required: false,
                  description: "Number of days of activity to aggregate for computing the concept popularity/trend score (default is 7 days).",
                  schema: { type: :integer }

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
        description "Retrieve details, settings, and popularity metrics of a single concept by ID.

### Integration Tip:
- Includes the semantic description, similarity thresholds, parent concept mappings, and scores."
        produces "application/json"
        parameter name: :id, in: :path, required: true,
                  description: "Unique concept numerical ID.",
                  schema: { type: :integer }
        parameter name: :days, in: :query, required: false,
                  description: "Number of days of activity to aggregate for the concept popularity/trend score.",
                  schema: { type: :integer }

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
        description "Update concept metadata such as description, similarity threshold, and custom score.

### Parameter Guidelines:
- **similarity_threshold**: Cosine distance threshold (range 0.0 to 1.0) determining how closely an article's embedding must align with the concept's anchor embedding to be classified under it."
        consumes "application/json"
        produces "application/json"
        parameter name: :id, in: :path, required: true,
                  description: "Unique concept numerical ID.",
                  schema: { type: :integer }
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
        description "Retrieve articles classified under this concept.

### Parameter Guidelines:
- **sort**: Set to `score` to sort articles by article popularity score descending. If omitted or set to any other value, sorting defaults to cosine similarity (closest first) secondary sorted by article score."
        produces "application/json"
        parameter name: :id, in: :path, required: true,
                  description: "Unique concept numerical ID.",
                  schema: { type: :integer }
        parameter name: :sort, in: :query, required: false,
                  description: "Sorting criteria: `score` or default.",
                  schema: { type: :string }
        parameter name: :page, in: :query, required: false,
                  description: "Pagination page index.",
                  schema: { type: :integer }
        parameter name: :per_page, in: :query, required: false,
                  description: "Number of items to return per page.",
                  schema: { type: :integer }

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
        description "Retrieve all concepts in the system including system and draft concepts. Admin credentials required."
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
        description "Create a new Concept.

### Parameters:
- **name**: Human readable label for the concept.
- **description**: Detailed semantic definition used to generate the anchor embedding.
- **similarity_threshold**: Target similarity threshold for categorizing articles under this concept.
- **parent_id**: ID of parent concept, if establishing a hierarchy."
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
        description "Retrieve full details of a specific concept by ID. Admin credentials required."
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
        description "Update concept properties. Admin credentials required."
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
        description "Permanently delete a concept by ID. Admin credentials required."
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
        description "Trigger a background backfill worker to scan historical articles published in the last `N` days and evaluate them against this concept."
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
