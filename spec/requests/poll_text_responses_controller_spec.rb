require "rails_helper"

RSpec.describe "PollText-responsesController", type: :request do
  let(:user) { create(:user) }
  let(:survey) { create(:survey, allow_resubmission: true) }
  let(:poll) { create(:poll, survey: survey, type_of: :text_input) }

  before do
    sign_in user
  end

  describe "POST /polls/:id/poll_text_responses" do
    context "when poll belongs to a survey with resubmission allowed" do
      it "creates a new text response with session_start" do
        expect do
          post "/polls/#{poll.id}/poll_text_responses", params: {
            poll_text_response: {
              text_content: "Test response",
              session_start: 1
            }
          }
        end.to change { PollTextResponse.count }.by(1)

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)

        text_response = PollTextResponse.last
        expect(text_response.user).to eq(user)
        expect(text_response.poll).to eq(poll)
        expect(text_response.text_content).to eq("Test response")
        expect(text_response.session_start).to eq(1)
      end

      it "allows creating multiple responses for the same poll in different sessions" do
        # Create first response
        create(:poll_text_response, user: user, poll: poll, text_content: "First response", session_start: 1)

        # Create second response in different session
        expect do
          post "/polls/#{poll.id}/poll_text_responses", params: {
            poll_text_response: {
              text_content: "Second response",
              session_start: 2
            }
          }
        end.to change { PollTextResponse.count }.by(1)

        expect(response).to have_http_status(:ok)

        responses = PollTextResponse.where(user: user, poll: poll)
        expect(responses.count).to eq(2)
        expect(responses.where(session_start: 1).first.text_content).to eq("First response")
        expect(responses.where(session_start: 2).first.text_content).to eq("Second response")
      end
    end

    context "when poll belongs to a survey with resubmission not allowed" do
      let(:survey) { create(:survey, allow_resubmission: false) }

      before do
        # Create a response to complete the survey
        create(:poll_text_response, user: user, poll: poll, text_content: "First response", session_start: 1)
      end

      it "prevents creating new responses when survey is completed" do
        expect do
          post "/polls/#{poll.id}/poll_text_responses", params: {
            poll_text_response: {
              text_content: "Second response",
              session_start: 2
            }
          }
        end.not_to change { PollTextResponse.count }

        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Survey does not allow resubmission")
      end
    end

    context "when poll does not belong to a survey" do
      let(:poll) { create(:poll, article: create(:article), type_of: :text_input) }

      it "creates or updates response using old behavior" do
        expect do
          post "/polls/#{poll.id}/poll_text_responses", params: {
            poll_text_response: {
              text_content: "Test response"
            }
          }
        end.to change { PollTextResponse.count }.by(1)

        expect(response).to have_http_status(:ok)

        text_response = PollTextResponse.last
        expect(text_response.user).to eq(user)
        expect(text_response.poll).to eq(poll)
        expect(text_response.text_content).to eq("Test response")
        expect(text_response.session_start).to eq(0)
      end

      it "prevents creating a second response for the same user and poll" do
        existing_response = create(:poll_text_response, user: user, poll: poll, text_content: "First response")

        post "/polls/#{poll.id}/poll_text_responses", params: {
          poll_text_response: {
            text_content: "New response"
          }
        }

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("Poll has already been taken")

        # Verify the original response is unchanged
        existing_response.reload
        expect(existing_response.text_content).to eq("First response")
        expect(PollTextResponse.count).to eq(1) # No new response created
      end
    end
  end
end
