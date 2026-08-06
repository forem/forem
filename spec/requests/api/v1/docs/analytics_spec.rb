require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName
# rubocop:disable Layout/LineLength

RSpec.describe "Api::V1::Docs::Analytics" do
  let(:Accept) { "application/vnd.forem.api-v1+json" }
  let(:user) { create(:user) }
  let(:api_secret) { create(:api_secret, user: user) }

  describe "GET /analytics/totals" do
    path "/api/analytics/totals" do
      get "Retrieve analytics totals" do
        tags "analytics"
        description "Retrieve aggregated lifetime stats (views, reactions, comments) for articles.

### Scope Control:
- Specify `article_id` to query a single post's metrics.
- Specify `organization_id` to retrieve metrics across all articles owned by the target organization."
        produces "application/json"
        parameter name: :article_id, in: :query, required: false,
                  description: "Optional ID to limit totals to a single article.",
                  schema: { type: :integer }
        parameter name: :organization_id, in: :query, required: false,
                  description: "Optional ID to limit totals to an organization's articles.",
                  schema: { type: :integer }

        response "200", "successful" do
          let(:"api-key") { api_secret.secret }
          add_examples
          run_test!
        end
      end
    end
  end

  describe "GET /analytics/historical" do
    path "/api/analytics/historical" do
      get "Retrieve historical analytics" do
        tags "analytics"
        description "Retrieve historical analytics data graphed over a time range.

### Time Range Formats:
- **start**: Start date (e.g. `2024-01-01`). Required.
- **end**: End date (e.g. `2024-01-31`). Defaults to current date if omitted."
        produces "application/json"
        parameter name: :start, in: :query, required: true,
                  description: "Start date (YYYY-MM-DD format).",
                  schema: { type: :string }, example: "2024-01-01"
        parameter name: :end, in: :query, required: false,
                  description: "End date (YYYY-MM-DD format).",
                  schema: { type: :string }, example: "2024-01-31"
        parameter name: :article_id, in: :query, required: false,
                  description: "Limit stats to a single article.",
                  schema: { type: :integer }
        parameter name: :organization_id, in: :query, required: false,
                  description: "Limit stats to an organization's articles.",
                  schema: { type: :integer }

        response "200", "successful" do
          let(:"api-key") { api_secret.secret }
          let(:start) { "2024-01-01" }
          add_examples
          run_test!
        end
      end
    end
  end

  describe "GET /analytics/past_day" do
    path "/api/analytics/past_day" do
      get "Retrieve analytics for the past day" do
        tags "analytics"
        description "Retrieve real-time hourly analytics statistics for the last 24 hours. Used for live graphs."
        produces "application/json"
        parameter name: :article_id, in: :query, required: false, schema: { type: :integer }
        parameter name: :organization_id, in: :query, required: false, schema: { type: :integer }

        response "200", "successful" do
          let(:"api-key") { api_secret.secret }
          add_examples
          run_test!
        end
      end
    end
  end

  describe "GET /analytics/referrers" do
    path "/api/analytics/referrers" do
      get "Retrieve referrer analytics" do
        tags "analytics"
        description "Retrieve traffic referring domains and URL source tracking metrics for articles."
        produces "application/json"
        parameter name: :start, in: :query, required: false, schema: { type: :string }, example: "2024-01-01"
        parameter name: :end, in: :query, required: false, schema: { type: :string }, example: "2024-01-31"
        parameter name: :article_id, in: :query, required: false, schema: { type: :integer }
        parameter name: :organization_id, in: :query, required: false, schema: { type: :integer }

        response "200", "successful" do
          let(:"api-key") { api_secret.secret }
          add_examples
          run_test!
        end
      end
    end
  end

  describe "GET /analytics/top_contributors" do
    path "/api/analytics/top_contributors" do
      get "Retrieve top contributors analytics" do
        tags "analytics"
        description "Retrieve top organization contributors ordered by article engagement scores."
        produces "application/json"
        parameter name: :start, in: :query, required: false, schema: { type: :string }, example: "2024-01-01"
        parameter name: :end, in: :query, required: false, schema: { type: :string }, example: "2024-01-31"
        parameter name: :article_id, in: :query, required: false, schema: { type: :integer }
        parameter name: :organization_id, in: :query, required: false, schema: { type: :integer }

        response "200", "successful" do
          let(:"api-key") { api_secret.secret }
          add_examples
          run_test!
        end
      end
    end
  end

  describe "GET /analytics/follower_engagement" do
    path "/api/analytics/follower_engagement" do
      get "Retrieve follower engagement analytics" do
        tags "analytics"
        description "Retrieve stats detailing new follower growth and engagement over time."
        produces "application/json"
        parameter name: :start, in: :query, required: false, schema: { type: :string }, example: "2024-01-01"
        parameter name: :end, in: :query, required: false, schema: { type: :string }, example: "2024-01-31"

        response "200", "successful" do
          let(:"api-key") { api_secret.secret }
          add_examples
          run_test!
        end
      end
    end
  end

  describe "GET /analytics/dashboard" do
    path "/api/analytics/dashboard" do
      get "Retrieve dashboard analytics bundle" do
        tags "analytics"
        description "Retrieve a complete bundled metrics package (totals, history, top posts) for rendering dashboard landing pages."
        produces "application/json"
        parameter name: :start, in: :query, required: false, schema: { type: :string }, example: "2024-01-01"
        parameter name: :end, in: :query, required: false, schema: { type: :string }, example: "2024-01-31"
        parameter name: :article_id, in: :query, required: false, schema: { type: :integer }
        parameter name: :organization_id, in: :query, required: false, schema: { type: :integer }

        response "200", "successful" do
          let(:"api-key") { api_secret.secret }
          add_examples
          run_test!
        end
      end
    end
  end

  describe "GET /analytics/heatmap" do
    path "/api/analytics/heatmap" do
      get "Retrieve heatmap activity" do
        tags "analytics"
        description "Retrieve user activity heatmap metrics (commits, posts, reactions) grouped by weekdays and hours."
        produces "application/json"
        parameter name: :end, in: :query, required: false, schema: { type: :string }, example: "2024-12-31"

        response "200", "successful" do
          let(:"api-key") { api_secret.secret }
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
