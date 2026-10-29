require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup

describe "GET /videos" do
  before { create_list(:article, 2, :video) }

  path "/api/videos" do
    get "Articles with a video" do
      tags "videos", "articles"
      security []
      description "Retrieve a list of articles that contain uploaded videos.

### Videos Overview:
- Bypasses authentication (can be accessed publicly).
- Returns articles that are published and include a video asset.
- Articles are ordered by descending popularity (views, watch time, and reactions).
- By default, returns 24 video articles per page."
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
