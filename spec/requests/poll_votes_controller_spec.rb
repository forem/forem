require "rails_helper"

RSpec.describe "PollVotesController", type: :request do
  let(:user) { create(:user) }
  let(:survey) { create(:survey, allow_resubmission: true) }
  let(:poll) { create(:poll, survey: survey, type_of: :single_choice) }
  let(:option1) { create(:poll_option, poll: poll, markdown: "Option 1") }
  let(:option2) { create(:poll_option, poll: poll, markdown: "Option 2") }

  before do
    sign_in user
  end

  describe "GET /poll_votes/:id" do
    context "when poll belongs to a survey" do
      it "returns poll voting data" do
        get "/poll_votes/#{poll.id}"

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)

        expect(json_response["poll_id"]).to eq(poll.id)
        expect(json_response["voted"]).to be false
      end
    end
  end

  describe "POST /poll_votes" do
    context "when poll belongs to a survey with resubmission allowed" do
      it "creates a new vote with session_start" do
        expect do
          post "/poll_votes", params: {
            poll_vote: {
              poll_option_id: option1.id,
              session_start: 1
            }
          }
        end.to change { PollVote.count }.by(1)

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)

        vote = PollVote.last
        expect(vote.user).to eq(user)
        expect(vote.poll).to eq(poll)
        expect(vote.poll_option).to eq(option1)
        expect(vote.session_start).to eq(1)
      end

      it "allows creating multiple votes for the same poll in different sessions" do
        # Create first vote
        create(:poll_vote, user: user, poll: poll, poll_option: option1, session_start: 1)

        # Create second vote in different session
        expect do
          post "/poll_votes", params: {
            poll_vote: {
              poll_option_id: option2.id,
              session_start: 2
            }
          }
        end.to change { PollVote.count }.by(1)

        expect(response).to have_http_status(:ok)

        votes = PollVote.where(user: user, poll: poll)
        expect(votes.count).to eq(2)
        expect(votes.where(session_start: 1).first.poll_option).to eq(option1)
        expect(votes.where(session_start: 2).first.poll_option).to eq(option2)
      end
    end

    context "when poll belongs to a survey with resubmission not allowed" do
      let(:survey) { create(:survey, allow_resubmission: false) }

      before do
        # Create a vote to complete the survey
        create(:poll_vote, user: user, poll: poll, poll_option: option1, session_start: 1)
      end

      it "prevents creating new votes when survey is completed" do
        expect do
          post "/poll_votes", params: {
            poll_vote: {
              poll_option_id: option2.id,
              session_start: 2
            }
          }
        end.not_to change { PollVote.count }

        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Survey does not allow resubmission")
      end
    end

    context "when poll does not belong to a survey" do
      let(:poll) { create(:poll, article: create(:article), type_of: :single_choice) }

      it "creates or updates vote using old behavior" do
        expect do
          post "/poll_votes", params: {
            poll_vote: {
              poll_option_id: option1.id
            }
          }
        end.to change { PollVote.count }.by(1)

        expect(response).to have_http_status(:ok)

        vote = PollVote.last
        expect(vote.user).to eq(user)
        expect(vote.poll).to eq(poll)
        expect(vote.poll_option).to eq(option1)
        expect(vote.session_start).to eq(0)
      end

      it "updates existing vote for the same user and poll" do
        existing_vote = create(:poll_vote, user: user, poll: poll, poll_option: option1)

        expect do
          post "/poll_votes", params: {
            poll_vote: {
              poll_option_id: option2.id
            }
          }
        end.not_to change { PollVote.count }

        expect(response).to have_http_status(:ok)

        existing_vote.reload
        expect(existing_vote.poll_option).to eq(option2)
      end
    end
  end
end
