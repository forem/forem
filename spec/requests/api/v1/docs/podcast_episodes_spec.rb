require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName

RSpec.describe "Api::V1::Docs::PodcastEpisodes" do
  let(:Accept) { "application/vnd.forem.api-v1+json" }
  let!(:podcast) { create(:podcast, slug: "codenewbie") }

  before { create(:podcast_episode, podcast: podcast) }

  describe "GET /podcast_episodes" do
    path "/api/podcast_episodes" do
      get "Podcast Episodes" do
        security []
        tags "podcast_episodes"
        description(<<-DESCRIBE.strip)
        Retrieve a list of podcast episodes published on the platform.

        ### Integration Guidance:
        - Bypasses authentication (can be accessed publicly).
        - Only returns active episodes belonging to published/reachable podcasts.
        - Episodes are returned in reverse chronological order based on their publication date.
        - The `username` query parameter is the unique slug of the podcast channel (e.g. `codenewbie`).

        It supports pagination, each page will contain 30 episodes by default.
        DESCRIBE
        operationId "getPodcastEpisodes"
        produces "application/json"
        parameter "$ref": "#/components/parameters/pageParam"
        parameter "$ref": "#/components/parameters/perPageParam30to1000"
        parameter name: :username, in: :query, required: false,
                  description: "Filters episodes by the unique slug (username) of the podcast (e.g. 'codenewbie').",
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
