require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup, RSpec/VariableName
RSpec.describe "Api::V1::Docs::RelatedArticles" do
  let(:Accept) { "application/vnd.forem.api-v1+json" }
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }
  let(:organization_id) { organization.id }
  let(:"api-key") { create(:api_secret, user: user).secret }

  before do
    create(:organization_membership, organization: organization, user: user)
    create(:article, title: "PostgreSQL guide")
    FeatureFlag.enable(:org_related_articles, FeatureFlag::Actor[organization])
  end

  path "/api/related_articles" do
    get "Discover public community articles" do
      tags "articles"
      operationId "getRelatedArticles"
      description "Requires active membership and the org_related_articles feature for organization_id. " \
                  "Query supports up to five comma-separated alternative names and date bounds. In keyword " \
                  "matching, a name of several words matches those words next to each other; hybrid semantic " \
                  "candidates are not phrase-filtered and need not contain the phrase. Page size is " \
                  "capped at 100, page at 1000. Keyword mode sorts newest first unless sort=relevance. " \
                  "Each result carries discovery_rank, a relevance score comparable within one " \
                  "response but not across responses. Hybrid mode fuses at most 100 " \
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
                description: "Technology names, for example PostgreSQL,Postgres. Up to five " \
                             "comma-separated searches. In keyword matching, a search of several " \
                             "words matches those words next to each other, so Tiger Data matches " \
                             "that phrase rather than mentions of tiger and data separately; hybrid " \
                             "semantic candidates are not phrase-filtered and need not contain the phrase."
      parameter name: :sort, in: :query, required: false,
                schema: { type: :string, enum: %w[recent relevance], default: "recent" },
                description: "recent returns newest first. relevance ranks by match strength, " \
                             "which accounts for how often a term occurs and whether it appears " \
                             "in the title rather than the body."
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
                  { type: :object,
                    required: %w[discovery_match],
                    properties: { discovery_match: { type: :array,
                                                     items: { type: :string,
                                                              enum: %w[keyword semantic] } },
                                  discovery_rank: { type: :number,
                                                    description: "Relevance score, comparable " \
                                                                 "within one response only." } } }]
        }
        run_test!
      end

      response "401", "Authentication required" do
        let(:q) { "PostgreSQL" }
        let(:"api-key") { "invalid" }
        run_test!
      end

      response "404", "Organization not found" do
        let(:organization_id) { 0 }
        let(:q) { "PostgreSQL" }
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
