require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName

RSpec.describe "Api::V1::Docs::PodcastEpisodes", appmap: false do
  let(:Accept) { "application/vnd.forem.api-v1+json" }
  let!(:podcast) { create(:podcast, slug: "codenewbie") }

  before { create(:podcast_episode, podcast: podcast) }

  describe "GET /podcast_episodes" do
    path "/api/podcast_episodes" do
      get "Podcast Episodes" do
        security []
        tags "podcast_episodes"
        description(<<-DESCRIBE.strip)
        This endpoint allows the client to retrieve a list of podcast episodes.
        "Podcast episodes" are episodes belonging to podcasts.
        It will only return active (reachable) podcast episodes that belong to published podcasts available on the platform, ordered by descending publication date.
        It supports pagination, each page will contain 30 articles by default.
        DESCRIBE
        operationId "getPodcastEpisodes"
        produces "application/json"
        parameter "$ref": "#/components/parameters/pageParam"
        parameter "$ref": "#/components/parameters/perPageParam30to1000"
        parameter name: :username, in: :query, required: false,
                  description: "Using this parameter will retrieve episodes belonging to a specific podcast.",
                  schema: { type: :string },
                  example: "codenewbie"

        response "200", "A List of Podcast episodes" do
          let(:"api-key") { nil }
          schema  type: :array,
                  items: { "$ref": "#/components/schemas/PodcastEpisodeIndex" }
          add_examples

          run_test!
        end

        response "200", "A List of Podcast episodes filtered by username" do
          let(:username) { "codenewbie" }
          schema  type: :array,
                  items: { "$ref": "#/components/schemas/PodcastEpisodeIndex" }
          add_examples

          run_test!
        end

        response "404", "Unknown Podcast username" do
          let(:username) { "unknown" }
          add_examples

          run_test!
        end
      end
    end
  end
end

# rubocop:enable RSpec/EmptyExampleGroup
# rubocop:enable RSpec/VariableName
