require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName
# rubocop:disable Layout/LineLength

RSpec.describe "Api::V1::Docs::Trends" do
  let(:Accept) { "application/vnd.forem.api-v1+json" }
  let!(:trend) { create(:trend, name: "Ruby 3.4 release", score: 15.5, description: "Discussions around the latest Ruby 3.4 features") }
  let!(:article) { create(:article, published: true, title: "Ruby 3.4 features deep dive") }

  before do
    create(:trend_membership, trend: trend, article: article, distance: 0.05)
  end

  describe "GET /trends" do
    path "/api/trends" do
      get "Trends" do
        security []
        tags "trends"
        description "This endpoint allows the client to retrieve a list of active trends.

Trends represent topics or themes that are currently hot and heavily discussed in the community.
It will return trends ordered by score and recency.

It supports pagination, each page will contain 10 trends by default."
        operationId "getTrends"
        produces "application/json"
        parameter "$ref": "#/components/parameters/pageParam"
        parameter "$ref": "#/components/parameters/perPageParam10to1000"

        response "200", "A List of Trends" do
          schema type: :array,
                 items: { "$ref": "#/components/schemas/Trend" }
          add_examples

          run_test!
        end
      end
    end
  end

  describe "GET /trends/{id_or_slug}" do
    path "/api/trends/{id_or_slug}" do
      get "A Trend" do
        security []
        tags "trends"
        description "This endpoint allows the client to retrieve details of a single trend using either its numeric ID or unique slug."
        operationId "getTrend"
        produces "application/json"
        parameter name: :id_or_slug, in: :path, type: :string, required: true,
                  description: "The ID or slug of the trend to retrieve.",
                  example: "ruby-3-4-release"

        response "200", "A Trend" do
          let(:id_or_slug) { trend.slug }
          schema type: :object,
                 items: { "$ref": "#/components/schemas/Trend" }
          add_examples

          run_test!
        end

        response "404", "Trend Not Found" do
          let(:id_or_slug) { "does-not-exist" }
          add_examples

          run_test!
        end
      end
    end
  end

  describe "GET /trends/{trend_id_or_slug}/articles" do
    path "/api/trends/{trend_id_or_slug}/articles" do
      get "Articles in a Trend" do
        security []
        tags "trends"
        description "This endpoint allows the client to retrieve a list of published articles belonging to a trend.

Articles will be ordered by their proximity (distance) to the trend's centroid, then by article score.
It supports pagination, each page will contain 10 articles by default."
        operationId "getTrendArticles"
        produces "application/json"
        parameter name: :trend_id_or_slug, in: :path, type: :string, required: true,
                  description: "The ID or slug of the trend to retrieve articles for.",
                  example: "ruby-3-4-release"
        parameter "$ref": "#/components/parameters/pageParam"
        parameter "$ref": "#/components/parameters/perPageParam10to1000"

        response "200", "A List of Articles in the Trend" do
          let(:trend_id_or_slug) { trend.slug }
          schema type: :array,
                 items: { "$ref": "#/components/schemas/ArticleIndex" }
          add_examples

          run_test!
        end

        response "404", "Trend Not Found" do
          let(:trend_id_or_slug) { "does-not-exist" }
          add_examples

          run_test!
        end
      end
    end
  end
end

# rubocop:enable Layout/LineLength
# rubocop:enable RSpec/VariableName
# rubocop:enable RSpec/EmptyExampleGroup
