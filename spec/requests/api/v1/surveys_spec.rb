require "rails_helper"

RSpec.describe "Api::V1::Surveys" do
  let(:headers) { { "Accept" => "application/vnd.forem.api-v1+json" } }
  let(:user) { create(:user) }
  let(:api_secret) { create(:api_secret, user: user) }
  let(:auth_headers) { headers.merge({ "api-key" => api_secret.secret }) }

  describe "GET /api/surveys" do
    context "when unauthenticated" do
      it "returns unauthorized" do
        get api_surveys_path, headers: headers
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
      before do
        user.add_role(:admin)
        create(:survey, active: true, title: "Active Survey")
        create(:survey, active: false, title: "Inactive Survey")
      end

      it "returns both active and inactive surveys" do
        get api_surveys_path, headers: auth_headers
        expect(response).to have_http_status(:ok)

        json_response = response.parsed_body
        expect(json_response.size).to eq(2)
      end

      it "filters by active status when param provided" do
        get api_surveys_path, params: { active: true }, headers: auth_headers
        expect(response).to have_http_status(:ok)

        json_response = response.parsed_body
        expect(json_response.size).to eq(1)
        expect(json_response.first["title"]).to eq("Active Survey")
      end

      it "filters by inactive status when param provided" do
        get api_surveys_path, params: { active: false }, headers: auth_headers
        expect(response).to have_http_status(:ok)

        json_response = response.parsed_body
        expect(json_response.size).to eq(1)
        expect(json_response.first["title"]).to eq("Inactive Survey")
      end

      it "paginates results" do
        create_list(:survey, 10)
        get api_surveys_path, params: { per_page: 8 }, headers: auth_headers
        expect(response).to have_http_status(:ok)

        json_response = response.parsed_body
        expect(json_response.size).to eq(8)
      end

      it "returns expected fields" do
        get api_surveys_path, headers: auth_headers
        expect(response).to have_http_status(:ok)

        survey_json = response.parsed_body.first
        expect(survey_json).to include(
          "id", "title", "slug", "type_of", "active",
          "display_title", "allow_resubmission",
          "survey_type_of", "created_at", "updated_at"
        )
      end

      it "returns empty array when no surveys exist" do
        Survey.destroy_all
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
        get api_survey_path(survey.id), headers: headers
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

      let!(:survey) { create(:survey, title: "Test Survey") }
      let!(:poll) do
        create(:poll, survey: survey, article: nil, prompt_markdown: "What do you think?")
      end

      it "returns survey by id with nested polls and options", :aggregate_failures do
        get api_survey_path(survey.id), headers: auth_headers
        expect(response).to have_http_status(:ok)

        json_response = response.parsed_body
        expect(json_response["id"]).to eq(survey.id)
        expect(json_response["title"]).to eq("Test Survey")
        expect(json_response["polls"]).to be_an(Array)
        expect(json_response["polls"].size).to eq(1)

        poll_json = json_response["polls"].first
        expect(poll_json["id"]).to eq(poll.id)
        expect(poll_json["prompt_markdown"]).to eq("What do you think?")
        expect(poll_json["poll_options"]).to be_an(Array)
        expect(poll_json["poll_options"].size).to eq(poll.poll_options.count)
      end

      it "returns survey by slug" do
        get api_survey_path(survey.slug), headers: auth_headers
        expect(response).to have_http_status(:ok)

        json_response = response.parsed_body
        expect(json_response["id"]).to eq(survey.id)
      end

      it "returns survey by old_slug" do
        old_slug = survey.slug
        survey.update!(slug: "new-slug-#{SecureRandom.hex(4)}")
        survey.reload

        get api_survey_path(old_slug), headers: auth_headers
        expect(response).to have_http_status(:ok)

        json_response = response.parsed_body
        expect(json_response["id"]).to eq(survey.id)
      end

      it "returns inactive surveys" do
        survey.update!(active: false)
        get api_survey_path(survey.id), headers: auth_headers
        expect(response).to have_http_status(:ok)

        json_response = response.parsed_body
        expect(json_response["active"]).to be(false)
      end

      it "returns 404 for nonexistent survey" do
        get api_survey_path("nonexistent"), headers: auth_headers
        expect(response).to have_http_status(:not_found)
      end

      it "returns poll options with expected fields" do
        get api_survey_path(survey.id), headers: auth_headers

        option_json = response.parsed_body.dig("polls", 0, "poll_options", 0)
        expect(option_json).to include(
          "id", "markdown", "processed_html", "position",
          "poll_votes_count", "supplementary_text"
        )
      end

      it "returns polls with expected fields" do
        get api_survey_path(survey.id), headers: auth_headers

        poll_json = response.parsed_body["polls"].first
        expect(poll_json).to include(
          "id", "prompt_markdown", "prompt_html", "type_of",
          "position", "poll_votes_count", "poll_skips_count",
          "poll_options_count", "scale_min", "scale_max",
          "poll_type_of", "created_at", "updated_at"
        )
      end
    end
  end

  describe "GET /api/surveys/:id_or_slug/responses" do
    context "when unauthenticated" do
      let!(:survey) { create(:survey) }

      it "returns unauthorized" do
        get responses_api_survey_path(survey.id), headers: headers
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authenticated but not admin" do
      let!(:survey) { create(:survey) }

      it "returns unauthorized" do
        get responses_api_survey_path(survey.id), headers: auth_headers
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authenticated" do
      let!(:survey) { create(:survey) }
      let!(:poll) { create(:poll, survey: survey, article: nil) }
      let!(:text_poll) { create(:poll, :text_input, survey: survey, article: nil) }
      let(:voter) { create(:user) }

      before do
        user.add_role(:admin)
        create(:poll_vote, poll: poll, poll_option: poll.poll_options.first, user: voter)
        create(:poll_text_response, poll: text_poll, user: voter, text_content: "Great survey!")
      end

      it "returns poll votes and text responses" do
        get responses_api_survey_path(survey.id), headers: auth_headers
        expect(response).to have_http_status(:ok)

        json_response = response.parsed_body
        expect(json_response["poll_votes"]).to be_an(Array)
        expect(json_response["poll_votes"].size).to eq(1)
        expect(json_response["text_responses"]).to be_an(Array)
        expect(json_response["text_responses"].size).to eq(1)
      end

      it "returns expected fields for poll votes" do
        get responses_api_survey_path(survey.id), headers: auth_headers

        vote_json = response.parsed_body["poll_votes"].first
        expect(vote_json).to include(
          "type_of", "id", "poll_id", "poll_option_id", "user_id",
          "user_email", "session_start", "created_at"
        )
        expect(vote_json["poll_id"]).to eq(poll.id)
        expect(vote_json["user_id"]).to eq(voter.id)
      end

      it "returns expected fields for text responses" do
        get responses_api_survey_path(survey.id), headers: auth_headers

        text_json = response.parsed_body["text_responses"].first
        expect(text_json).to include(
          "type_of", "id", "poll_id", "user_id", "text_content",
          "user_email", "session_start", "created_at"
        )
        expect(text_json["text_content"]).to eq("Great survey!")
      end

      it "paginates results" do
        other_users = create_list(:user, 5)
        other_users.each do |u|
          create(:poll_vote, poll: poll, poll_option: poll.poll_options.first, user: u)
        end

        get responses_api_survey_path(survey.id), params: { per_page: 2 }, headers: auth_headers
        expect(response).to have_http_status(:ok)

        json_response = response.parsed_body
        expect(json_response["poll_votes"].size).to eq(2)
      end

      it "returns empty arrays for survey with no responses" do
        empty_survey = create(:survey)
        create(:poll, survey: empty_survey, article: nil)

        get responses_api_survey_path(empty_survey.id), headers: auth_headers
        expect(response).to have_http_status(:ok)

        json_response = response.parsed_body
        expect(json_response["poll_votes"]).to eq([])
        expect(json_response["text_responses"]).to eq([])
      end

      it "returns 404 for nonexistent survey" do
        get responses_api_survey_path("nonexistent"), headers: auth_headers
        expect(response).to have_http_status(:not_found)
      end

      it "filters responses created after the given since timestamp" do
        old_vote = create(:poll_vote, poll: poll, poll_option: poll.poll_options.first,
                                      user: create(:user), created_at: 1.hour.ago)
        newer_vote = create(:poll_vote, poll: poll, poll_option: poll.poll_options.first,
                                        user: create(:user), created_at: 1.minute.ago)

        get responses_api_survey_path(survey.id),
            params: { since: 30.minutes.ago.iso8601 },
            headers: auth_headers
        expect(response).to have_http_status(:ok)

        returned_ids = response.parsed_body["poll_votes"].pluck("id")
        expect(returned_ids).to include(newer_vote.id)
        expect(returned_ids).not_to include(old_vote.id)
      end

      it "returns all responses when since param is omitted" do
        get responses_api_survey_path(survey.id), headers: auth_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["poll_votes"].size).to eq(1)
        expect(response.parsed_body["text_responses"].size).to eq(1)
      end
    end
  end
end
