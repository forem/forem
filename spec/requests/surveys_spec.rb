require "rails_helper"

RSpec.describe "Surveys", type: :request do
  describe "GET /surveys/:id/votes" do
    let(:user) { create(:user) }
    let(:survey) { create(:survey) }
    let!(:poll_1) { create(:poll, survey_id: survey.id) }
    let!(:poll_2) { create(:poll, survey_id: survey.id) }
    let!(:other_poll) { create(:poll) } # A poll not in the survey

    context "when user is not signed in" do
      it "returns an unauthorized status" do
        get "/surveys/#{survey.id}/votes"
        # The status might be 401 Unauthorized or 302 Found for a redirect,
        # depending on your authentication setup (e.g., Devise).
        expect(response).not_to have_http_status(:ok)
      end
    end

    context "when user is signed in" do
      before { sign_in user }

      it "returns an empty votes object if the user has not voted on any poll" do
        get "/surveys/#{survey.id}/votes"

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["votes"]).to be_empty
      end

      it "returns the user's votes for polls within the survey" do
        option_for_poll_1 = poll_1.poll_options.first
        create(:poll_vote, user: user, poll: poll_1, poll_option: option_for_poll_1)

        get "/surveys/#{survey.id}/votes"

        expect(response).to have_http_status(:ok)
        votes = response.parsed_body["votes"]

        expect(votes.size).to eq(1)
        # Note: JSON keys are strings, so we convert poll_1.id to a string.
        expect(votes[poll_1.id.to_s]).to eq(option_for_poll_1.id)
        expect(votes).not_to have_key(poll_2.id.to_s)
      end

      it "does not include votes for polls outside the specified survey" do
        option_for_poll_1 = poll_1.poll_options.first
        create(:poll_vote, user: user, poll: poll_1, poll_option: option_for_poll_1)

        # Create a vote for a poll that is NOT in the survey
        option_for_other_poll = other_poll.poll_options.first
        create(:poll_vote, user: user, poll: other_poll, poll_option: option_for_other_poll)

        get "/surveys/#{survey.id}/votes"

        expect(response).to have_http_status(:ok)
        votes = response.parsed_body["votes"]

        # The response should ONLY include votes for polls in the requested survey.
        expect(votes.size).to eq(1)
        expect(votes).to have_key(poll_1.id.to_s)
        expect(votes).not_to have_key(other_poll.id.to_s)
      end
    end
  end
end