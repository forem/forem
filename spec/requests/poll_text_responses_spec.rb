require "rails_helper"

RSpec.describe "PollTextResponses", type: :request do
  let(:user) { create(:user) }
  let(:poll) { create(:poll, :text_input) }

  before do
    sign_in user
  end

  describe "POST /poll_text_responses" do
    context "with valid parameters" do
      it "creates a new text response" do
        expect do
          post "/polls/#{poll.id}/poll_text_responses", params: {
            poll_text_response: {
              text_content: "This is my text response"
            }
          }
        end.to change(PollTextResponse, :count).by(1)

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to be true
        expect(json_response["message"]).to eq("Text response submitted successfully")
      end
    end

    context "with invalid parameters" do
      it "returns error for empty text content" do
        expect do
          post "/polls/#{poll.id}/poll_text_responses", params: {
            poll_text_response: {
              text_content: ""
            }
          }
        end.not_to change(PollTextResponse, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to be false
        expect(json_response["errors"]).to include("Text content can't be blank")
      end

      it "returns error for text content too long" do
        expect do
          post "/polls/#{poll.id}/poll_text_responses", params: {
            poll_text_response: {
              text_content: "a" * 1001
            }
          }
        end.not_to change(PollTextResponse, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to be false
        expect(json_response["errors"]).to include("Text content is too long (maximum is 1000 characters)")
      end

      it "creates a new text response when user submits again" do
        create(:poll_text_response, poll: poll, user: user, text_content: "First response", session_start: 1)

        expect do
          post "/polls/#{poll.id}/poll_text_responses", params: {
            poll_text_response: {
              text_content: "Second response",
              session_start: 2
            }
          }
        end.to change(PollTextResponse, :count).by(1)

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to be true
        expect(json_response["message"]).to eq("Text response submitted successfully")

        # Verify the new response was created
        new_response = PollTextResponse.last
        expect(new_response.text_content).to eq("Second response")
        expect(new_response.session_start).to eq(2)
      end
    end

    context "when user is not authenticated" do
      before { sign_out user }

      it "redirects to sign in" do
        post "/polls/#{poll.id}/poll_text_responses", params: {
          poll_text_response: {
            text_content: "This is my text response"
          }
        }

        expect(response).to redirect_to("/magic_links/new")
      end
    end
  end
end
