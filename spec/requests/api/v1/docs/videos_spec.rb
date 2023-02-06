require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup

describe "GET /videos" do
  before { create_list(:article, 2, :video) }

  path "/api/videos" do
    get "Articles with a video" do
      tags "videos", "articles"
      security []
      description "This endpoint allows the client to retrieve a list of articles that are uploaded with a video.

It will only return published video articles ordered by descending popularity.

It supports pagination, each page will contain 24 articles by default."
      operationId "videos"
      produces "application/json"
      parameter "$ref": "#/components/parameters/pageParam"
      parameter "$ref": "#/components/parameters/perPageParam24to1000"

      response "200", "A List of all articles with videos" do
        schema  type: :array,
                items: { "$ref": "#/components/schemas/VideoArticle" }
        add_examples

        run_test!
      end
    end
  end
end

# rubocop:enable RSpec/EmptyExampleGroup
