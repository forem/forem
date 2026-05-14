require "rails_helper"

RSpec.describe SurveysController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user) }
  let(:survey) { create(:survey) }
  let(:poll) { create(:poll, survey: survey) }

  before do
    create(:poll_option, poll: poll)
  end

  describe "GET #show" do
    render_views

    it "finds survey by slug" do
      get :show, params: { slug: survey.slug }
      expect(response).to have_http_status(:ok)
      expect(assigns(:survey)).to eq(survey)
    end

    it "redirects when finding by old_slug" do
      old_slug = survey.slug
      survey.update(slug: "new-slug")

      get :show, params: { slug: old_slug }
      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to(survey_path(slug: "new-slug"))
    end

    it "redirects when finding by old_old_slug" do
      old_old_slug = survey.slug
      survey.update(slug: "old-slug")
      survey.update(slug: "new-slug")

      get :show, params: { slug: old_old_slug }
      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to(survey_path(slug: "new-slug"))
    end

    it "returns 404 for inactive survey" do
      survey.update(active: false)
      get :show, params: { slug: survey.slug }
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for unknown slug" do
      get :show, params: { slug: "unknown" }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET #votes" do
    context "when user is not authenticated" do
      it "redirects to sign in" do
        get :votes, params: { id: survey.id }
        expect(response).to have_http_status(:found) # 302 redirect
      end
    end

    context "when user is authenticated" do
      before do
        sign_in user
      end

      context "when user has not completed the survey" do
        it "returns correct response data" do
          get :votes, params: { id: survey.id }

          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)

          expect(json_response["votes"]).to eq({})
          expect(json_response["can_submit"]).to be true
          expect(json_response["completed"]).to be false
          expect(json_response["allow_resubmission"]).to be false
          expect(json_response["current_session"]).to eq(0)
          expect(json_response["new_session"]).to be_nil
        end
      end

      context "when user has completed the survey" do
        before do
          create(:poll_vote, user: user, poll: poll, session_start: 1)
        end

        context "when resubmission is not allowed" do
          it "returns correct response data" do
            get :votes, params: { id: survey.id }

            expect(response).to have_http_status(:ok)
            json_response = JSON.parse(response.body)

            expect(json_response["votes"]).to have_key(poll.id.to_s)
            expect(json_response["can_submit"]).to be false
            expect(json_response["completed"]).to be true
            expect(json_response["allow_resubmission"]).to be false
            expect(json_response["current_session"]).to eq(1)
            expect(json_response["new_session"]).to be_nil
          end
        end

        context "when resubmission is allowed" do
          let(:survey) { create(:survey, allow_resubmission: true) }

          it "returns correct response data with new session" do
            get :votes, params: { id: survey.id }

            expect(response).to have_http_status(:ok)
            json_response = JSON.parse(response.body)

            # For resubmission surveys, the backend returns empty votes (new session)
            # and the frontend will start fresh
            expect(json_response["votes"]).to eq({})
            expect(json_response["can_submit"]).to be true
            expect(json_response["completed"]).to be true
            expect(json_response["allow_resubmission"]).to be true
            expect(json_response["current_session"]).to eq(1)
            expect(json_response["new_session"]).to eq(2)
          end
        end
      end

      context "when survey has text input polls" do
        let(:text_poll) { create(:poll, survey: survey, type_of: :text_input) }

        before do
          create(:poll_text_response, user: user, poll: text_poll, text_content: "Test response", session_start: 1)
        end

        it "includes text responses in the votes data" do
          get :votes, params: { id: survey.id }

          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)

          expect(json_response["votes"]).to have_key(text_poll.id.to_s)
          expect(json_response["votes"][text_poll.id.to_s]).to eq("Test response")
        end
      end
    end
  end
end
