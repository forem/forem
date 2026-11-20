require "rails_helper"

RSpec.describe "Api::V0::Surveys" do
  let(:api_secret) { create(:api_secret, user: create(:user, :without_profile, profile_image: nil)) }
  let(:user) { api_secret.user }
  let(:auth_headers) { { "api-key" => api_secret.secret } }

  describe "GET /api/surveys" do
    context "when unauthenticated" do
      it "returns unauthorized" do
        get api_surveys_path
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authenticated but not admin" do
      it "returns unauthorized" do
        get api_surveys_path, headers: auth_headers
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authenticated" do
      before { user.add_role(:admin) }

      it "returns surveys with expected fields, filters by active status, and paginates", :aggregate_failures do
        create(:survey, active: true, title: "Active Survey")
        create(:survey, active: false, title: "Inactive Survey")

        get api_surveys_path, headers: auth_headers
        expect(response).to have_http_status(:ok)

        json_response = response.parsed_body
        expect(json_response.size).to eq(2)

        get api_surveys_path, params: { active: true }, headers: auth_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.pluck("title")).to eq(["Active Survey"])

        get api_surveys_path, params: { active: false }, headers: auth_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.pluck("title")).to eq(["Inactive Survey"])

        get api_surveys_path, params: { per_page: 1 }, headers: auth_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.size).to eq(1)

        survey_json = response.parsed_body.first
        expect(survey_json).to include(
          "id", "title", "slug", "type_of", "active",
          "display_title", "allow_resubmission",
          "survey_type_of", "created_at", "updated_at"
        )
      end

      it "returns empty array when no surveys exist" do
        get api_surveys_path, headers: auth_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq([])
      end
    end
  end

  describe "GET /api/surveys/:id_or_slug" do
    context "when unauthenticated" do
      let!(:survey) { create(:survey) }

      it "returns unauthorized" do
        get api_survey_path(survey.id)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authenticated but not admin" do
      let!(:survey) { create(:survey) }

      it "returns unauthorized" do
        get api_survey_path(survey.id), headers: auth_headers
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authenticated" do
      before { user.add_role(:admin) }

      let(:survey) { create(:survey, title: "Test Survey") }
      let(:poll) do
        create(:poll, survey: survey, article: nil, prompt_markdown: "What do you think?")
      end

      it "returns survey by slug, old_slug, and when inactive", :aggregate_failures do
        get api_survey_path(survey.slug), headers: auth_headers
        expect(response).to have_http_status(:ok)

        json_response = response.parsed_body
        expect(json_response["id"]).to eq(survey.id)

        old_slug = survey.slug
        survey.update!(slug: "new-slug-#{SecureRandom.hex(4)}")

        get api_survey_path(old_slug), headers: auth_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["id"]).to eq(survey.id)

        survey.update!(active: false)

        get api_survey_path(survey.id), headers: auth_headers
        expect(response).to have_http_status(:ok)

        json_response = response.parsed_body
        expect(json_response["id"]).to eq(survey.id)
        expect(json_response["active"]).to be(false)
      end

      it "returns 404 for nonexistent survey" do
        get api_survey_path("nonexistent"), headers: auth_headers
        expect(response).to have_http_status(:not_found)
      end

      it "returns survey by id with nested polls and options and expected fields", :aggregate_failures do
        poll
        get api_survey_path(survey.id), headers: auth_headers
        expect(response).to have_http_status(:ok)

        json_response = response.parsed_body
        expect(json_response["id"]).to eq(survey.id)
        expect(json_response["title"]).to eq("Test Survey")
        expect(json_response["polls"]).to be_an(Array)
        expect(json_response["polls"].size).to eq(1)

        option_json = response.parsed_body.dig("polls", 0, "poll_options", 0)
        expect(option_json).to include(
          "id", "markdown", "processed_html", "position",
          "poll_votes_count", "supplementary_text"
        )

        poll_json = response.parsed_body["polls"].first
        expect(poll_json["id"]).to eq(poll.id)
        expect(poll_json["prompt_markdown"]).to eq("What do you think?")
        expect(poll_json["poll_options"]).to be_an(Array)
        expect(poll_json["poll_options"].size).to eq(poll.poll_options.count)
        expect(poll_json).to include(
          "id", "prompt_markdown", "prompt_html", "type_of",
          "position", "poll_votes_count", "poll_skips_count",
          "poll_options_count", "scale_min", "scale_max",
          "poll_type_of", "created_at", "updated_at"
        )
      end
    end
  end

  describe "GET /api/surveys/:id_or_slug/poll_votes" do
    context "when unauthenticated" do
      let!(:survey) { create(:survey) }

      it "returns unauthorized" do
        get poll_votes_api_survey_path(survey.id)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authenticated but not admin" do
      let!(:survey) { create(:survey) }

      it "returns unauthorized" do
        get poll_votes_api_survey_path(survey.id), headers: auth_headers
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authenticated" do
      let(:survey) { create(:survey) }
      let(:poll) { create(:poll, survey: survey, article: nil) }
      let(:voter) { create(:user, :without_profile, profile_image: nil) }

      before { user.add_role(:admin) }

      it "returns poll votes with expected fields, paginates, and filters by after", :aggregate_failures do
        first_vote = create(:poll_vote, poll: poll, poll_option: poll.poll_options.first, user: voter)
        other_voter = create(:user, :without_profile, profile_image: nil)
        second_vote = create(:poll_vote, poll: poll, poll_option: poll.poll_options.first, user: other_voter)

        get poll_votes_api_survey_path(survey.id), headers: auth_headers
        expect(response).to have_http_status(:ok)

        json_response = response.parsed_body
        expect(json_response).to be_an(Array)
        expect(json_response.size).to eq(2)

        vote_json = response.parsed_body.first
        expect(vote_json).to include(
          "type_of", "id", "poll_id", "poll_option_id", "user_id",
          "user_email", "session_start", "created_at"
        )
        expect(vote_json["poll_id"]).to eq(poll.id)
        expect(vote_json["user_id"]).to eq(voter.id)

        get poll_votes_api_survey_path(survey.id), params: { per_page: 1 }, headers: auth_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.size).to eq(1)
        expect(response.parsed_body.pluck("id")).to eq([first_vote.id])

        get poll_votes_api_survey_path(survey.id), params: { after: first_vote.id }, headers: auth_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.pluck("id")).to eq([second_vote.id])
      end

      it "returns empty array for survey with no votes" do
        poll
        get poll_votes_api_survey_path(survey.id), headers: auth_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq([])
      end

      it "returns 404 for nonexistent survey" do
        get poll_votes_api_survey_path("nonexistent"), headers: auth_headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /api/surveys/:id_or_slug/poll_text_responses" do
    context "when unauthenticated" do
      let!(:survey) { create(:survey) }

      it "returns unauthorized" do
        get poll_text_responses_api_survey_path(survey.id)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authenticated but not admin" do
      let!(:survey) { create(:survey) }

      it "returns unauthorized" do
        get poll_text_responses_api_survey_path(survey.id), headers: auth_headers
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authenticated" do
      let(:survey) { create(:survey) }
      let(:text_poll) { create(:poll, :text_input, survey: survey, article: nil) }
      let(:voter) { create(:user, :without_profile, profile_image: nil) }

      before { user.add_role(:admin) }

      it "returns text responses with expected fields, paginates, and filters by after", :aggregate_failures do
        first_response = create(:poll_text_response, poll: text_poll, user: voter, text_content: "Great survey!")
        other_voter = create(:user, :without_profile, profile_image: nil)
        second_response = create(:poll_text_response, poll: text_poll, user: other_voter, text_content: "Another")

        get poll_text_responses_api_survey_path(survey.id), headers: auth_headers
        expect(response).to have_http_status(:ok)

        json_response = response.parsed_body
        expect(json_response).to be_an(Array)
        expect(json_response.size).to eq(2)

        text_json = response.parsed_body.first
        expect(text_json).to include(
          "type_of", "id", "poll_id", "user_id", "text_content",
          "user_email", "session_start", "created_at"
        )
        expect(text_json["text_content"]).to eq("Great survey!")

        get poll_text_responses_api_survey_path(survey.id), params: { per_page: 1 }, headers: auth_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.size).to eq(1)
        expect(response.parsed_body.pluck("id")).to eq([first_response.id])

        get poll_text_responses_api_survey_path(survey.id), params: { after: first_response.id }, headers: auth_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.pluck("id")).to eq([second_response.id])
      end

      it "returns empty array for survey with no text responses" do
        text_poll
        get poll_text_responses_api_survey_path(survey.id), headers: auth_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq([])
      end

      it "returns 404 for nonexistent survey" do
        get poll_text_responses_api_survey_path("nonexistent"), headers: auth_headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /api/surveys" do
    context "when unauthenticated" do
      it "returns unauthorized" do
        post api_surveys_path, params: { survey: { title: "API Survey" } }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authenticated but not admin" do
      it "returns unauthorized" do
        post api_surveys_path, params: { survey: { title: "API Survey" } }, headers: auth_headers
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authenticated as admin" do
      before do
        user.add_role(:admin)
      end

      it "creates a survey with basic params" do
        post api_surveys_path, params: { survey: { title: "API Survey", active: true } }, headers: auth_headers
        expect(response).to have_http_status(:created)
        expect(response.parsed_body["title"]).to eq("API Survey")
        expect(response.parsed_body["active"]).to be(true)
      end

      it "creates a survey with nested polls and options using clean JSON keys" do
        params = {
          survey: {
            title: "Nested Clean Survey",
            survey_type_of: "community_pulse",
            polls: [
              {
                prompt_markdown: "Favorite editor?",
                poll_type_of: "single_choice",
                poll_options: [
                  { markdown: "Vim" },
                  { markdown: "VS Code" },
                ]
              },
            ]
          }
        }
        expect do
          post api_surveys_path, params: params, headers: auth_headers, as: :json
        end.to change(Survey, :count).by(1).and change(Poll, :count).by(1).and change(PollOption, :count).by(2)

        expect(response).to have_http_status(:created)
        json = response.parsed_body
        expect(json["polls"].size).to eq(1)
        expect(json["polls"].first["poll_options"].pluck("markdown")).to eq(["Vim", "VS Code"])
      end

      it "returns unprocessable entity for invalid parameters" do
        post api_surveys_path, params: { survey: { title: "" } }, headers: auth_headers
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["errors"]).to include("Title can't be blank")
      end
    end
  end

  describe "PATCH /api/surveys/:id_or_slug" do
    let(:survey) { create(:survey, title: "Original Survey") }

    context "when unauthenticated" do
      it "returns unauthorized" do
        patch api_survey_path(survey.id), params: { survey: { title: "New Title" } }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authenticated but not admin" do
      it "returns unauthorized" do
        patch api_survey_path(survey.id), params: { survey: { title: "New Title" } }, headers: auth_headers
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authenticated as admin" do
      before do
        user.add_role(:admin)
      end

      it "updates basic survey attributes" do
        patch api_survey_path(survey.id), params: { survey: { title: "Updated Title" } }, headers: auth_headers
        expect(response).to have_http_status(:ok)
        expect(survey.reload.title).to eq("Updated Title")
      end

      it "updates nested polls and options" do
        poll = create(:poll, survey: survey, article: nil, prompt_markdown: "Old prompt",
                             poll_options_input_array: ["Option A", "Option B"])
        option = poll.poll_options.first
        other_option = poll.poll_options.second

        params = {
          survey: {
            polls: [
              {
                id: poll.id,
                prompt_markdown: "New prompt",
                poll_options: [
                  { id: option.id, markdown: "New option" },
                  { id: other_option.id, _destroy: true },
                  { markdown: "Added option" },
                ]
              },
            ]
          }
        }
        patch api_survey_path(survey.id), params: params, headers: auth_headers, as: :json
        expect(response).to have_http_status(:ok)

        poll.reload
        expect(poll.prompt_markdown).to eq("New prompt")
        expect(poll.poll_options.map(&:markdown)).to contain_exactly("New option", "Added option")
      end

      it "destroys a poll when _destroy is passed" do
        poll = create(:poll, survey: survey, article: nil)
        params = {
          survey: {
            polls: [
              { id: poll.id, _destroy: true },
            ]
          }
        }
        patch api_survey_path(survey.id), params: params, headers: auth_headers, as: :json
        expect(response).to have_http_status(:ok)
        expect(survey.polls.reload).to be_empty
      end

      it "returns 404 for nonexistent survey" do
        patch api_survey_path("nonexistent"), params: { survey: { title: "Title" } }, headers: auth_headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /api/surveys/:id_or_slug" do
    let(:survey) { create(:survey) }

    context "when unauthenticated" do
      it "returns unauthorized" do
        delete api_survey_path(survey.id)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authenticated but not admin" do
      it "returns unauthorized" do
        delete api_survey_path(survey.id), headers: auth_headers
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authenticated as admin" do
      before do
        user.add_role(:admin)
      end

      it "destroys the survey" do
        survey
        expect do
          delete api_survey_path(survey.id), headers: auth_headers
        end.to change(Survey, :count).by(-1)
        expect(response).to have_http_status(:no_content)
      end

      it "returns 404 for nonexistent survey" do
        delete api_survey_path("nonexistent"), headers: auth_headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
