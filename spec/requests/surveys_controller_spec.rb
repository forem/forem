require "rails_helper"

RSpec.describe "SurveysController", type: :request do
  let(:user) { create(:user) }
  let(:survey) { create(:survey, allow_resubmission: true) }
  let(:poll1) { create(:poll, survey: survey, type_of: :single_choice) }
  let(:poll2) { create(:poll, survey: survey, type_of: :text_input) }
  let(:option1) { create(:poll_option, poll: poll1, markdown: "Option 1") }
  let(:option2) { create(:poll_option, poll: poll1, markdown: "Option 2") }

  before do
    sign_in user
  end

  describe "GET /survey/:slug" do
    it "renders the show page for an active survey" do
      get "/survey/#{survey.slug}"
      expect(response).to have_http_status(:ok)
    end

    it "redirects when using an old slug" do
      old_slug = survey.slug
      survey.update(slug: "new-slug")
      
      get "/survey/#{old_slug}"
      expect(response).to redirect_to("/survey/new-slug")
      expect(response.status).to eq(301)
    end

    it "redirects when using an old old slug" do
      slug1 = survey.slug
      survey.update(slug: "slug-2")
      survey.update(slug: "slug-3")
      
      get "/survey/#{slug1}"
      expect(response).to redirect_to("/survey/slug-3")
      expect(response.status).to eq(301)
    end

    it "returns 404 for non-existent survey" do
      get "/survey/non-existent-slug"
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for inactive survey" do
      survey.update(active: false)
      get "/survey/#{survey.slug}"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /survey/:slug/votes" do
    context "when user has not completed the survey" do
      it "returns empty votes and allows submission" do
        # Ensure polls are created
        expect(poll1).to be_persisted
        expect(poll2).to be_persisted

        get "/survey/#{survey.slug}/votes"

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)

        expect(json_response["votes"]).to be_empty
        expect(json_response["can_submit"]).to be true
        expect(json_response["completed"]).to be false
        expect(json_response["allow_resubmission"]).to be true
      end
    end

    context "when user has completed the survey with resubmission allowed" do
      before do
        # Create votes for the user to complete the survey
        create(:poll_vote, user: user, poll: poll1, poll_option: option1, session_start: 1)
        create(:poll_text_response, user: user, poll: poll2, text_content: "Test response", session_start: 1)
      end

      it "returns empty votes for new session and allows resubmission" do
        get "/survey/#{survey.slug}/votes"

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)

        expect(json_response["votes"]).to be_empty
        expect(json_response["can_submit"]).to be true
        expect(json_response["completed"]).to be true
        expect(json_response["allow_resubmission"]).to be true
        expect(json_response["new_session"]).to be_present
      end
    end

    context "when user has completed the survey with resubmission not allowed" do
      let(:survey) { create(:survey, allow_resubmission: false) }

      before do
        # Create votes for the user to complete the survey
        create(:poll_vote, user: user, poll: poll1, poll_option: option1, session_start: 1)
        create(:poll_text_response, user: user, poll: poll2, text_content: "Test response", session_start: 1)
      end

      it "returns existing votes and prevents resubmission" do
        get "/survey/#{survey.slug}/votes"

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)

        expect(json_response["votes"]).to include("#{poll1.id}" => option1.id)
        expect(json_response["votes"]).to include("#{poll2.id}" => "Test response")
        expect(json_response["can_submit"]).to be false
        expect(json_response["completed"]).to be true
        expect(json_response["allow_resubmission"]).to be false
      end
    end
  end
end
