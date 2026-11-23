require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup, RSpec/VariableName
RSpec.describe "Api::V1::Docs::OrganizationArticleAnalytics" do
  let(:Accept) { "application/vnd.forem.api-v1+json" }
  let(:user) { create(:user) }
  let(:"api-key") { create(:api_secret, user: user).secret }
  let(:organization) { create(:organization) }
  let(:organization_id) { organization.id }

  before do
    create(:article, organization: organization)
    FeatureFlag.enable(:org_article_analytics, FeatureFlag::Actor[organization])
  end

  path "/api/organizations/{organization_id}/article_analytics" do
    get "Export article analytics for an organization" do
      tags "analytics"
      operationId "getOrganizationArticleAnalytics"
      description "Requires the org_article_analytics organization feature and active membership. " \
                  "Members and admins can export published organization posts with stored lifetime counters. " \
                  "This includes article identifiers, URLs, page views, public reactions and comments. " \
                  "Counters are eventual lifetime totals. updated_at describes the " \
                  "article and is not a cursor for metric changes. Results use the current subforem and ID order. " \
                  "Page size is capped at 100 and page depth at 1000. " \
                  "Pass start and end together (YYYY-MM-DD, UTC, inclusive, at most 90 days) to add a daily " \
                  "series to each article with page views, comments and reactions by category, including " \
                  "reading list saves (counts only). reactions.total includes saves, as in the historical " \
                  "analytics endpoint. Days without activity are returned with zero counts. Daily values come " \
                  "from eventual rollups, so recent days may still be revised. An article whose rollup has not " \
                  "been built yet returns zeros for every day even if it had activity, and its past days can " \
                  "change once the rollup is first populated. " \
                  "Independent posts that mention the organization are excluded. Responses are never cached."
      produces "application/json"
      parameter name: :organization_id, in: :path, required: true, schema: { type: :integer }
      parameter name: :page, in: :query, required: false,
                schema: { type: :integer, minimum: 1, maximum: 1000, default: 1 }
      parameter name: :per_page, in: :query, required: false,
                schema: { type: :integer, minimum: 1, maximum: 100, default: 30 }
      parameter name: :start, in: :query, required: false,
                description: "First day of the daily series (YYYY-MM-DD). Requires end.",
                schema: { type: :string, format: :date }, example: "2026-03-01"
      parameter name: :end, in: :query, required: false,
                description: "Last day of the daily series (YYYY-MM-DD), at most 89 days after start. Requires start.",
                schema: { type: :string, format: :date }, example: "2026-03-31"

      response "200", "Organization article metrics" do
        let(:user) { create(:organization_membership, organization: organization).user }
        let(:start) { "2026-03-01" }
        let(:end) { "2026-03-02" }

        schema type: :array, items: {
          type: :object,
          required: %w[id title path url user_id organization_id published_at updated_at
                       page_views_count public_reactions_count comments_count],
          properties: {
            id: { type: :integer }, title: { type: :string }, path: { type: :string },
            url: { type: :string }, user_id: { type: :integer }, organization_id: { type: :integer },
            published_at: { type: :string, format: :"date-time" },
            updated_at: { type: :string, format: :"date-time" },
            page_views_count: { type: :integer }, public_reactions_count: { type: :integer },
            comments_count: { type: :integer },
            daily: {
              type: :array,
              description: "Present only when start and end are given.",
              items: {
                type: :object,
                required: %w[date page_views comments reactions],
                properties: {
                  date: { type: :string, format: :date },
                  page_views: { type: :integer },
                  comments: { type: :integer },
                  reactions: {
                    type: :object,
                    required: %w[total like readinglist unicorn exploding_head raised_hands fire],
                    properties: {
                      total: { type: :integer }, like: { type: :integer }, readinglist: { type: :integer },
                      unicorn: { type: :integer }, exploding_head: { type: :integer },
                      raised_hands: { type: :integer }, fire: { type: :integer }
                    }
                  }
                }
              }
            }
          }
        }
        run_test!
      end

      response "401", "Organization membership or feature access required" do
        run_test!
      end

      response "422", "Invalid date range" do
        let(:user) { create(:organization_membership, organization: organization).user }
        let(:start) { "2026-03-02" }
        let(:end) { "2026-03-01" }

        schema type: :object,
               required: %w[error status],
               properties: {
                 error: { type: :string },
                 status: { type: :integer, example: 422 }
               }
        run_test!
      end

      response "404", "Organization not found" do
        let(:organization_id) { 0 }
        run_test!
      end
    end
  end
end
# rubocop:enable RSpec/EmptyExampleGroup, RSpec/VariableName
