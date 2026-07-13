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
        description "Retrieve a list of active trends.

### Trends Overview & Score Calculation:
- Trends represent hot topics or semantic themes currently being heavily discussed in the community.
- They are computed by clustering semantic concept embeddings of recently published articles.
- The `score` reflects the volume and engagement (views, comments, reactions) of articles associated with the trend.
- Returned trends are ordered by score and recency.
- Publicly accessible without authentication.

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
        description "Retrieve details of a single trend using either its numeric ID or unique slug.

### Usage Guidance:
- Useful for loading details of a trending topic (description, score, and slug details) to render header sections on trending tag or topic pages."
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
        description "Retrieve a list of published articles belonging to a trend.

### Article Ordering & Proximity:
- Articles are mapped to trends based on their embedding distance to the trend's centroid.
- Returned articles are ordered by proximity/similarity (distance) first (most relevant posts first), and then by overall article engagement score.
- Supports pagination, each page will contain 10 articles by default."
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
