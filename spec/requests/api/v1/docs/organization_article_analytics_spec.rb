require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup, RSpec/VariableName
RSpec.describe "Api::V1::Docs::OrganizationArticleAnalytics" do
  let(:Accept) { "application/vnd.forem.api-v1+json" }
  let(:user) { create(:user) }
  let(:"api-key") { create(:api_secret, user: user).secret }
  let(:organization) { create(:organization) }
  let(:organization_id) { organization.id }

  path "/api/organizations/{organization_id}/article_analytics" do
    get "Export article analytics for an organization" do
      tags "analytics"
      operationId "getOrganizationArticleAnalytics"
      description "Requires the org_article_analytics organization feature and active membership. " \
                  "Members and admins can export published organization posts with stored lifetime counters. " \
                  "This includes article identifiers, URLs, page views, public reactions and comments. " \
                  "Counters are eventual lifetime totals, not date-range analytics. updated_at describes the " \
                  "article and is not a cursor for metric changes. Results use the current subforem and ID order. " \
                  "Page size is capped at 100 and page depth at 1000. " \
                  "Independent posts that mention the organization are excluded. Responses are never cached."
      produces "application/json"
      parameter name: :organization_id, in: :path, required: true, schema: { type: :integer }
      parameter name: :page, in: :query, required: false,
                schema: { type: :integer, minimum: 1, maximum: 1000, default: 1 }
      parameter name: :per_page, in: :query, required: false,
                schema: { type: :integer, minimum: 1, maximum: 100, default: 30 }

      response "200", "Organization article metrics" do
        before do
          create(:organization_membership, organization: organization, user: user)
          FeatureFlag.enable(:org_article_analytics, FeatureFlag::Actor[organization])
        end

        schema type: :array, items: {
          type: :object,
          required: %w[id title url page_views_count public_reactions_count comments_count],
          properties: {
            id: { type: :integer }, title: { type: :string }, url: { type: :string },
            page_views_count: { type: :integer }, public_reactions_count: { type: :integer },
            comments_count: { type: :integer }
          }
        }
        run_test!
      end

      response "401", "Organization membership or feature access required" do
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
