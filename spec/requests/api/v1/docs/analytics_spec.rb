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

  describe "GET /analytics/historical" do
    path "/api/analytics/historical" do
      get "Retrieve historical analytics" do
        tags "analytics"
        produces "application/json"
        parameter name: :start, in: :query, required: true, schema: { type: :string }, example: "2024-01-01"
        parameter name: :end, in: :query, required: false, schema: { type: :string }, example: "2024-01-31"
        parameter name: :article_id, in: :query, required: false, schema: { type: :integer }
        parameter name: :organization_id, in: :query, required: false, schema: { type: :integer }

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
