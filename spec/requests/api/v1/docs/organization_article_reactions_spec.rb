require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup, RSpec/VariableName
RSpec.describe "Api::V1::Docs::OrganizationArticleReactions" do
  let(:Accept) { "application/vnd.forem.api-v1+json" }
  let(:user) { create(:user) }
  let(:"api-key") { create(:api_secret, user: user).secret }
  let(:organization) { create(:organization) }
  let(:organization_id) { organization.id }

  before do
    create(:organization_membership, organization: organization, user: user, type_of_user: "admin")
    create(:reaction, reactable: create(:article, organization: organization))
    FeatureFlag.enable(:org_article_reactions, FeatureFlag::Actor[organization])
  end

  path "/api/organizations/{organization_id}/article_reactions" do
    get "List reactions on an organization's articles" do
      tags "organizations"
      operationId "getOrganizationArticleReactions"
      description "Requires the org_article_reactions organization feature and organization admin access. " \
                  "Lists public reactions on the organization's published articles in the current subforem, " \
                  "newest first (created_at, then id). Reading list saves and privileged moderation reactions " \
                  "are never included. Results reflect current reactions, not an event log: removed reactions " \
                  "and reactions from deleted users disappear. Page size is capped at 100 and page depth at 1000. " \
                  "Responses are never cached."
      produces "application/json"
      parameter name: :organization_id, in: :path, required: true, schema: { type: :integer }
      parameter name: :article_id, in: :query, required: false, schema: { type: :integer },
                description: "Only reactions on this article; must be a positive integer, otherwise 422. " \
                             "Articles outside the organization return no results."
      parameter name: :since, in: :query, required: false, schema: { type: :string, format: :"date-time" },
                description: "Only reactions created at or after this RFC 3339 timestamp, " \
                             "which must include a UTC offset (for example 2026-11-18T00:00:00Z)."
      parameter name: :page, in: :query, required: false,
                schema: { type: :integer, minimum: 1, maximum: 1000, default: 1 }
      parameter name: :per_page, in: :query, required: false,
                schema: { type: :integer, minimum: 1, maximum: 100, default: 30 }

      response "200", "Article reactions" do
        schema type: :array, items: {
          type: :object,
          required: %w[article_id category created_at user],
          properties: {
            article_id: { type: :integer },
            category: { type: :string },
            created_at: { type: :string, format: :"date-time" },
            user: {
              type: :object,
              required: %w[user_id username name github_username twitter_username],
              properties: {
                user_id: { type: :integer },
                username: { type: :string },
                name: { type: :string },
                github_username: { type: :string, nullable: true },
                twitter_username: { type: :string, nullable: true }
              }
            }
          }
        }
        run_test!
      end

      response "401", "Organization admin access or feature access required" do
        let(:"api-key") { create(:api_secret).secret }
        run_test!
      end

      response "404", "Organization not found" do
        let(:organization_id) { 0 }
        run_test!
      end

      response "422", "Invalid since timestamp or article_id" do
        let(:since) { "yesterday" }
        run_test!
      end
    end
  end
end
# rubocop:enable RSpec/EmptyExampleGroup, RSpec/VariableName
