require "rails_helper"

RSpec.describe "Api::V0::Surveys" do
  let(:api_secret) { create(:api_secret) }
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
      let!(:survey) { create(:survey) }
      let!(:poll) { create(:poll, survey: survey, article: nil) }
      let(:voter) { create(:user) }

      before do
        user.add_role(:admin)
        create(:poll_vote, poll: poll, poll_option: poll.poll_options.first, user: voter)
      end

      it "returns poll votes" do
        get poll_votes_api_survey_path(survey.id), headers: auth_headers
        expect(response).to have_http_status(:ok)

        json_response = response.parsed_body
        expect(json_response).to be_an(Array)
        expect(json_response.size).to eq(1)
      end

      it "returns expected fields for poll votes" do
        get poll_votes_api_survey_path(survey.id), headers: auth_headers

        vote_json = response.parsed_body.first
        expect(vote_json).to include(
          "type_of", "id", "poll_id", "poll_option_id", "user_id",
          "user_email", "session_start", "created_at"
        )
        expect(vote_json["poll_id"]).to eq(poll.id)
        expect(vote_json["user_id"]).to eq(voter.id)
      end

      it "paginates results" do
        other_users = create_list(:user, 5)
        other_users.each do |u|
          create(:poll_vote, poll: poll, poll_option: poll.poll_options.first, user: u)
        end

        get poll_votes_api_survey_path(survey.id), params: { per_page: 2 }, headers: auth_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.size).to eq(2)
      end

      it "returns empty array for survey with no votes" do
        empty_survey = create(:survey)
        create(:poll, survey: empty_survey, article: nil)

        get poll_votes_api_survey_path(empty_survey.id), headers: auth_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq([])
      end

      it "returns 404 for nonexistent survey" do
        get poll_votes_api_survey_path("nonexistent"), headers: auth_headers
        expect(response).to have_http_status(:not_found)
      end

      it "returns only votes after the given ID" do
        first_vote = PollVote.order(:id).first
        second_vote = create(:poll_vote, poll: poll, poll_option: poll.poll_options.first,
                                         user: create(:user))

        get poll_votes_api_survey_path(survey.id),
            params: { after: first_vote.id },
            headers: auth_headers
        expect(response).to have_http_status(:ok)

        returned_ids = response.parsed_body.pluck("id")
        expect(returned_ids).to include(second_vote.id)
        expect(returned_ids).not_to include(first_vote.id)
      end

      it "returns all votes when after param is omitted" do
        get poll_votes_api_survey_path(survey.id), headers: auth_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.size).to eq(1)
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
      let!(:survey) { create(:survey) }
      let!(:text_poll) { create(:poll, :text_input, survey: survey, article: nil) }
      let(:voter) { create(:user) }

      before do
        user.add_role(:admin)
        create(:poll_text_response, poll: text_poll, user: voter, text_content: "Great survey!")
      end

      it "returns text responses" do
        get poll_text_responses_api_survey_path(survey.id), headers: auth_headers
        expect(response).to have_http_status(:ok)

        json_response = response.parsed_body
        expect(json_response).to be_an(Array)
        expect(json_response.size).to eq(1)
      end

      it "returns expected fields for text responses" do
        get poll_text_responses_api_survey_path(survey.id), headers: auth_headers

        text_json = response.parsed_body.first
        expect(text_json).to include(
          "type_of", "id", "poll_id", "user_id", "text_content",
          "user_email", "session_start", "created_at"
        )
        expect(text_json["text_content"]).to eq("Great survey!")
      end

      it "paginates results" do
        other_users = create_list(:user, 5)
        other_users.each do |u|
          create(:poll_text_response, poll: text_poll, user: u, text_content: "Response")
        end

        get poll_text_responses_api_survey_path(survey.id), params: { per_page: 2 }, headers: auth_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.size).to eq(2)
      end

      it "returns empty array for survey with no text responses" do
        empty_survey = create(:survey)
        create(:poll, :text_input, survey: empty_survey, article: nil)

        get poll_text_responses_api_survey_path(empty_survey.id), headers: auth_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq([])
      end

      it "returns 404 for nonexistent survey" do
        get poll_text_responses_api_survey_path("nonexistent"), headers: auth_headers
        expect(response).to have_http_status(:not_found)
      end

      it "returns only text responses after the given ID" do
        first_response = PollTextResponse.order(:id).first
        second_response = create(:poll_text_response, poll: text_poll,
                                                      user: create(:user), text_content: "Another")

        get poll_text_responses_api_survey_path(survey.id),
            params: { after: first_response.id },
            headers: auth_headers
        expect(response).to have_http_status(:ok)

        returned_ids = response.parsed_body.pluck("id")
        expect(returned_ids).to include(second_response.id)
        expect(returned_ids).not_to include(first_response.id)
      end

      it "returns all text responses when after param is omitted" do
        get poll_text_responses_api_survey_path(survey.id), headers: auth_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.size).to eq(1)
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
                  { markdown: "VS Code" }
                ]
              }
            ]
          }
        }
        expect {
          post api_surveys_path, params: params, headers: auth_headers, as: :json
        }.to change(Survey, :count).by(1).and change(Poll, :count).by(1).and change(PollOption, :count).by(2)

        expect(response).to have_http_status(:created)
        json = response.parsed_body
        expect(json["polls"].size).to eq(1)
        expect(json["polls"].first["poll_options"].map { |o| o["markdown"] }).to eq(["Vim", "VS Code"])
      end

      it "returns unprocessable entity for invalid parameters" do
        post api_surveys_path, params: { survey: { title: "" } }, headers: auth_headers
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["errors"]).to include("Title can't be blank")
      end
    end
  end

  describe "PATCH /api/surveys/:id_or_slug" do
    let!(:survey) { create(:survey, title: "Original Survey") }

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
        poll = create(:poll, survey: survey, prompt_markdown: "Old prompt", poll_options_input_array: ["Option A", "Option B"])
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
                  { markdown: "Added option" }
                ]
              }
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
        poll = create(:poll, survey: survey)
        params = {
          survey: {
            polls: [
              { id: poll.id, _destroy: true }
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
    let!(:survey) { create(:survey) }

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
        expect {
          delete api_survey_path(survey.id), headers: auth_headers
        }.to change(Survey, :count).by(-1)
        expect(response).to have_http_status(:no_content)
      end

      it "returns 404 for nonexistent survey" do
        delete api_survey_path("nonexistent"), headers: auth_headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
