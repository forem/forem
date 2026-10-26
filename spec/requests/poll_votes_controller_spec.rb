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

      it "updates the existing vote when changing selection in the same session without reporting an error" do
        create(:poll_vote, user: user, poll: poll, poll_option: option1, session_start: 1)
        allow(Rails.error).to receive(:report)

        expect do
          post "/poll_votes", params: {
            poll_vote: {
              poll_option_id: option2.id,
              session_start: 1
            }
          }
        end.not_to change(PollVote, :count)

        expect(response).to have_http_status(:ok)
        expect(Rails.error).not_to have_received(:report)

        vote = PollVote.find_by(user: user, poll: poll, session_start: 1)
        expect(vote.poll_option).to eq(option2)
      end

      it "is idempotent when re-submitting the same option in the same session" do
        create(:poll_vote, user: user, poll: poll, poll_option: option1, session_start: 1)
        allow(Rails.error).to receive(:report)

        expect do
          post "/poll_votes", params: {
            poll_vote: {
              poll_option_id: option1.id,
              session_start: 1
            }
          }
        end.not_to change(PollVote, :count)

        expect(response).to have_http_status(:ok)
        expect(Rails.error).not_to have_received(:report)
      end

      it "updates existing vote for scale survey polls in the same session instead of creating duplicates" do
        scale_poll = create(:poll, :scale, survey: survey)
        scale_opt1 = scale_poll.poll_options.first
        scale_opt2 = scale_poll.poll_options.second

        create(:poll_vote, user: user, poll: scale_poll, poll_option: scale_opt1, session_start: 1)
        allow(Rails.error).to receive(:report)

        expect do
          post "/poll_votes", params: {
            poll_vote: {
              poll_option_id: scale_opt2.id,
              session_start: 1
            }
          }
        end.not_to change(PollVote, :count)

        expect(response).to have_http_status(:ok)
        expect(Rails.error).not_to have_received(:report)
        expect(PollVote.find_by(user: user, poll: scale_poll, session_start: 1).poll_option).to eq(scale_opt2)
      end

      it "handles multiple choice survey polls idempotently, prunes deselected options, and keeps counters accurate" do
        mc_poll = create(:poll, :multiple_choice, survey: survey)
        mc_opt1 = mc_poll.poll_options.first
        mc_opt2 = mc_poll.poll_options.second
        mc_opt3 = create(:poll_option, poll: mc_poll, markdown: "Option 3")

        create(:poll_vote, user: user, poll: mc_poll, poll_option: mc_opt1, session_start: 1)
        create(:poll_vote, user: user, poll: mc_poll, poll_option: mc_opt2, session_start: 1)
        allow(Rails.error).to receive(:report)

        # User goes back, unchecks mc_opt1, keeps mc_opt2, and checks mc_opt3
        post "/poll_votes", params: {
          poll_vote: {
            poll_option_id: mc_opt2.id,
            poll_option_ids: [mc_opt2.id, mc_opt3.id],
            session_start: 1
          }
        }
        # Repeated submission with same poll_option_ids is idempotent and does not double-decrement counters
        post "/poll_votes", params: {
          poll_vote: {
            poll_option_id: mc_opt3.id,
            poll_option_ids: [mc_opt2.id, mc_opt3.id],
            session_start: 1
          }
        }

        expect(response).to have_http_status(:ok)
        expect(Rails.error).not_to have_received(:report)

        recorded_option_ids = PollVote.where(user: user, poll: mc_poll, session_start: 1).pluck(:poll_option_id)
        expect(recorded_option_ids).to contain_exactly(mc_opt2.id, mc_opt3.id)
        expect(mc_poll.reload.poll_votes_count).to eq(2)
        expect([mc_opt1.reload.poll_votes_count, mc_opt2.reload.poll_votes_count, mc_opt3.reload.poll_votes_count])
          .to eq([0, 1, 1])
      end
    end

    context "when poll belongs to a survey with resubmission not allowed" do
      let(:survey) { create(:survey, allow_resubmission: false) }

      before do
        # Create a vote to complete the survey
        create(:poll_vote, user: user, poll: poll, poll_option: option1, session_start: 1)
      end

      it "returns success but does not create a vote when survey is completed (silent failure)" do
        expect do
          post "/poll_votes", params: {
            poll_vote: {
              poll_option_id: option2.id,
              session_start: 2
            }
          }
        end.not_to change { PollVote.count }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["voted"]).to be true
      end

      it "saves all options on the final multiple-choice poll in one request and blocks subsequent edits" do
        mc_poll = create(:poll, :multiple_choice, survey: survey)
        mc_opt1 = mc_poll.poll_options.first
        mc_opt2 = mc_poll.poll_options.second
        mc_opt3 = create(:poll_option, poll: mc_poll, markdown: "Option 3")

        expect(survey.completed_by_user?(user)).to be false

        # Single request with poll_option_ids records all selected options and completes the survey
        expect do
          post "/poll_votes", params: {
            poll_vote: {
              poll_option_id: mc_opt1.id,
              poll_option_ids: [mc_opt1.id, mc_opt2.id],
              session_start: 1
            }
          }
        end.to change { PollVote.where(user: user, poll: mc_poll, session_start: 1).count }.from(0).to(2)

        expect(survey.completed_by_user?(user)).to be true

        # Once the non-resubmission survey is completed, further edits to the multiple-choice poll are rejected
        expect do
          post "/poll_votes", params: {
            poll_vote: {
              poll_option_id: mc_opt3.id,
              poll_option_ids: [mc_opt3.id],
              session_start: 1
            }
          }
        end.not_to change { PollVote.where(user: user, poll: mc_poll, session_start: 1).pluck(:poll_option_id) }
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

      it "records multiple options and supports pruning via poll_option_ids for a regular multiple-choice poll" do
        mc_poll = create(:poll, :multiple_choice, article: create(:article))
        mc_opt1 = mc_poll.poll_options.first
        mc_opt2 = mc_poll.poll_options.second

        post "/poll_votes", params: { poll_vote: { poll_option_id: mc_opt1.id } }
        post "/poll_votes", params: { poll_vote: { poll_option_id: mc_opt2.id } }

        recorded_option_ids = PollVote.where(user: user, poll: mc_poll).pluck(:poll_option_id)
        expect(recorded_option_ids).to contain_exactly(mc_opt1.id, mc_opt2.id)

        post "/poll_votes", params: {
          poll_vote: {
            poll_option_id: mc_opt2.id,
            poll_option_ids: [mc_opt2.id]
          }
        }
        expect(PollVote.where(user: user, poll: mc_poll).pluck(:poll_option_id)).to contain_exactly(mc_opt2.id)
      end
    end
  end
end
