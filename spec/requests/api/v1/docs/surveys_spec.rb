require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName

RSpec.describe "Api::V1::Docs::Surveys" do
  let(:Accept) { "application/vnd.forem.api-v1+json" }
  let(:api_secret) { create(:api_secret) }
  let(:user) { api_secret.user }

  before do
    user.add_role(:admin)
  end

  describe "GET /api/surveys" do
    path "/api/surveys" do
      get "List surveys" do
        tags "surveys"
        description(<<~DESCRIBE.strip)
          This endpoint allows the client to retrieve a list of surveys.

          It supports pagination and optional filtering by active status.

          Internal only. Admin authorization is required to access this endpoint.
        DESCRIBE
        operationId "getSurveys"
        produces "application/json"
        parameter "$ref": "#/components/parameters/pageParam"
        parameter "$ref": "#/components/parameters/perPageParam30to1000"
        parameter name: :active, in: :query, required: false,
                  description: "Filter by active status. Omit to return all surveys.",
                  schema: { type: :boolean }

        response "200", "A list of surveys" do
          let(:"api-key") { api_secret.secret }

          before do
            create_list(:survey, 2)
          end

          schema type: :array,
                 items: { "$ref": "#/components/schemas/Survey" }
          add_examples

          run_test!
        end

        response "401", "Unauthorized" do
          let(:"api-key") { "invalid" }
          add_examples

          run_test!
        end
      end
    end
  end

  describe "GET /api/surveys/{id_or_slug}" do
    let(:survey) { create(:survey, title: "Test Survey") }

    before { create(:poll, survey: survey, article: nil, prompt_markdown: "What do you think?") }

    path "/api/surveys/{id_or_slug}" do
      get "A survey with polls" do
        tags "surveys"
        description(<<~DESCRIBE.strip)
          This endpoint allows the client to retrieve a single survey by ID or slug,
          including its nested polls and poll options.

          Internal only. Admin authorization is required to access this endpoint.
        DESCRIBE
        operationId "getSurveyByIdOrSlug"
        produces "application/json"

        parameter name: :id_or_slug, in: :path, required: true,
                  description: "The ID or slug of the survey.",
                  schema: { type: :string },
                  example: "community-pulse-2026"

        response "200", "A survey with nested polls and options" do
          let(:"api-key") { api_secret.secret }
          let(:id_or_slug) { survey.slug }

          schema "$ref": "#/components/schemas/SurveyWithPolls"
          add_examples

          run_test!
        end

        response "401", "Unauthorized" do
          let(:"api-key") { "invalid" }
          let(:id_or_slug) { survey.slug }
          add_examples

          run_test!
        end

        response "404", "Not found" do
          let(:"api-key") { api_secret.secret }
          let(:id_or_slug) { "nonexistent-slug" }

          add_examples

          run_test!
        end
      end
    end
  end

  describe "GET /api/surveys/{id_or_slug}/poll_votes" do
    let(:survey) { create(:survey) }
    let(:poll) { create(:poll, survey: survey, article: nil) }
    let(:voter) { create(:user) }

    before do
      create(:poll_vote, poll: poll, poll_option: poll.poll_options.first, user: voter)
    end

    path "/api/surveys/{id_or_slug}/poll_votes" do
      get "Survey poll votes" do
        tags "surveys"
        description(<<~DESCRIBE.strip)
          This endpoint allows the client to retrieve poll votes for a given survey.
          Results are paginated. Use the `after` parameter with the last seen vote ID
          for cursor-based pagination.

          Internal only. Admin authorization is required to access this endpoint.
        DESCRIBE
        operationId "getSurveyPollVotes"
        produces "application/json"

        parameter name: :id_or_slug, in: :path, required: true,
                  description: "The ID or slug of the survey.",
                  schema: { type: :string }
        parameter "$ref": "#/components/parameters/perPageParam30to1000"
        parameter name: :after, in: :query, required: false,
                  description: "Return only votes with an ID greater than this value.",
                  schema: { type: :integer },
                  example: 42

        response "200", "Poll votes" do
          let(:"api-key") { api_secret.secret }
          let(:id_or_slug) { survey.id }

          schema type: :array,
                 items: { "$ref": "#/components/schemas/PollVote" }
          add_examples

          run_test!
        end

        response "401", "Unauthorized" do
          let(:"api-key") { "invalid" }
          let(:id_or_slug) { survey.id }
          add_examples

          run_test!
        end

        response "404", "Not found" do
          let(:"api-key") { api_secret.secret }
          let(:id_or_slug) { "nonexistent" }

          add_examples

          run_test!
        end
      end
    end
  end

  describe "GET /api/surveys/{id_or_slug}/poll_text_responses" do
    let(:survey) { create(:survey) }
    let(:text_poll) { create(:poll, :text_input, survey: survey, article: nil) }
    let(:voter) { create(:user) }

    before do
      create(:poll_text_response, poll: text_poll, user: voter, text_content: "Great survey!")
    end

    path "/api/surveys/{id_or_slug}/poll_text_responses" do
      get "Survey poll text responses" do
        tags "surveys"
        description(<<~DESCRIBE.strip)
          This endpoint allows the client to retrieve text responses for a given survey.
          Results are paginated. Use the `after` parameter with the last seen response ID
          for cursor-based pagination.

          Internal only. Admin authorization is required to access this endpoint.
        DESCRIBE
        operationId "getSurveyPollTextResponses"
        produces "application/json"

        parameter name: :id_or_slug, in: :path, required: true,
                  description: "The ID or slug of the survey.",
                  schema: { type: :string }
        parameter "$ref": "#/components/parameters/perPageParam30to1000"
        parameter name: :after, in: :query, required: false,
                  description: "Return only text responses with an ID greater than this value.",
                  schema: { type: :integer },
                  example: 42

        response "200", "Poll text responses" do
          let(:"api-key") { api_secret.secret }
          let(:id_or_slug) { survey.id }

          schema type: :array,
                 items: { "$ref": "#/components/schemas/PollTextResponse" }
          add_examples

          run_test!
        end

        response "401", "Unauthorized" do
          let(:"api-key") { "invalid" }
          let(:id_or_slug) { survey.id }
          add_examples

          run_test!
        end

        response "404", "Not found" do
          let(:"api-key") { api_secret.secret }
          let(:id_or_slug) { "nonexistent" }

          add_examples

          run_test!
        end
      end
    end
  end
end

# rubocop:enable RSpec/VariableName
# rubocop:enable RSpec/EmptyExampleGroup
