require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup, RSpec/VariableName
RSpec.describe "Api::V1::Docs::CommunityArticles" do
  let(:Accept) { "application/vnd.forem.api-v1+json" }
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }
  let(:organization_id) { organization.id }
  let(:"api-key") { create(:api_secret, user: user).secret }

  before do
    create(:organization_membership, organization: organization, user: user)
    FeatureFlag.enable(:org_community_discovery, FeatureFlag::Actor[organization])
  end

  path "/api/community_articles" do
    get "Discover public community articles" do
      tags "articles"
      operationId "getCommunityArticles"
      description "Requires active membership and the org_community_discovery feature for organization_id. " \
                  "Query supports up to five comma-separated alternative names and date bounds. Page size is " \
                  "capped at 100, page at 1000. Keyword mode sorts newest first. Hybrid mode fuses at most 100 " \
                  "keyword and 100 semantic candidates using reciprocal rank fusion; it is not an exhaustive export. " \
                  "Semantic candidates require cosine distance <= 0.4. Query embeddings are cached for one hour. " \
                  "Missing vectors remain eligible for keyword matches; provider failures fall back to keyword. " \
                  "X-Discovery-Mode reports the effective mode; hybrid also returns X-Discovery-Candidate-Limit: 200 " \
                  "and X-Discovery-Exhaustive: false. discovery_match identifies keyword/semantic sources. " \
                  "Visibility, community, score and publication-date filters apply before candidate limits. " \
                  "Keyword matches include author/org metadata and are not literal body-mention counts."
      produces "application/json"
      parameter name: :organization_id, in: :query, required: true, schema: { type: :integer },
                description: "Organization granting discovery access; caller must be an active member."
      parameter name: :mode, in: :query, required: false,
                schema: { type: :string, enum: %w[keyword hybrid], default: "keyword" }
      parameter name: :q, in: :query, required: true, schema: { type: :string, maxLength: 500 },
                description: "Technology names, for example PostgreSQL,Postgres. Up to five searches."
      parameter name: :start, in: :query, required: false, schema: { type: :string, format: :date },
                description: "Inclusive publication date (YYYY-MM-DD)."
      parameter name: :end, in: :query, required: false, schema: { type: :string, format: :date },
                description: "Inclusive publication date (YYYY-MM-DD)."
      parameter name: :page, in: :query, required: false,
                schema: { type: :integer, minimum: 1, maximum: 1000, default: 1 }
      parameter name: :per_page, in: :query, required: false,
                schema: { type: :integer, minimum: 1, maximum: 100, default: 30 }

      response "200", "Public articles" do
        let(:q) { "PostgreSQL,Postgres" }
        schema type: :array, items: {
          allOf: [{ "$ref": "#/components/schemas/ArticleIndex" },
                  { type: :object, properties: { discovery_match: { type: :array,
                                                                    items: { type: :string,
                                                                             enum: %w[keyword semantic] } } } }]
        }
        run_test!
      end

      response "401", "Authentication required" do
        let(:q) { "PostgreSQL" }
        let(:"api-key") { "invalid" }
        run_test!
      end

      response "422", "Invalid query or date interval" do
        let(:q) { "!!!" }
        run_test!
      end
    end
  end
end
# rubocop:enable RSpec/EmptyExampleGroup, RSpec/VariableName
