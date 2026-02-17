require "rails_helper"

RSpec.describe "PollVotes", type: :request do
  let(:user) { create(:user) }
  let(:article) { create(:article) }
  let(:poll) { create(:poll, article_id: article.id) }

  before { sign_in user }

  describe "GET /poll_votes/:id" do
    # These specs remain unchanged and valid.
    it "returns proper results for poll" do
      get "/poll_votes/#{poll.id}"
      expect(response.parsed_body["voting_data"]["votes_count"]).to eq(0)
      expect(response.parsed_body["voting_data"]["votes_distribution"]).to include([poll.poll_options.first.id, 0])
      expect(response.parsed_body["poll_id"]).to eq(poll.id)
      expect(response.parsed_body["voted"]).to be(false)
    end

    it "returns proper results for poll if voted" do
      create(:poll_vote, user_id: user.id, poll_option_id: poll.poll_options.first.id, poll_id: poll.id)
      get "/poll_votes/#{poll.id}"
      expect(response.parsed_body["voting_data"]["votes_count"]).to eq(1)
      expect(response.parsed_body["voting_data"]["votes_distribution"]).to include([poll.poll_options.first.id, 1])
      expect(response.parsed_body["poll_id"]).to eq(poll.id)
      expect(response.parsed_body["voted"]).to be(true)
    end
  end

  describe "POST /poll_votes" do
    let(:option_1) { poll.poll_options.first }
    let(:option_2) { poll.poll_options.second }

    it "creates a vote for the current user" do
      post "/poll_votes", params: {
        poll_vote: { poll_option_id: option_1.id }
      }
      expect(response).to have_http_status(:ok)
      expect(user.poll_votes.count).to eq(1)
      expect(user.poll_votes.first.poll_option).to eq(option_1)
    end

    # This is the new, critical test for our vote-changing feature.
    it "allows the current user to change their vote" do
      # 1. Cast the first vote
      post "/poll_votes", params: { poll_vote: { poll_option_id: option_1.id } }
      expect(user.poll_votes.count).to eq(1)
      expect(user.poll_votes.first.poll_option).to eq(option_1)

      # 2. Change the vote to the second option
      post "/poll_votes", params: { poll_vote: { poll_option_id: option_2.id } }
      expect(response).to have_http_status(:ok)

      # 3. Verify the response shows the updated distribution
      parsed_body = response.parsed_body
      expect(parsed_body["voting_data"]["votes_count"]).to eq(1)
      expect(parsed_body["voting_data"]["votes_distribution"]).to include([option_1.id, 0])
      expect(parsed_body["voting_data"]["votes_distribution"]).to include([option_2.id, 1])

      # 4. Verify the database state
      expect(user.poll_votes.count).to eq(1) # Should still only have one vote record
      expect(user.poll_votes.first.poll_option).to eq(option_2) # The vote should now be for option_2
    end

    it "does not create a duplicate vote if the same option is voted for twice" do
      # This test remains valid and ensures idempotency for the same vote.
      2.times do
        post "/poll_votes", params: {
          poll_vote: { poll_option_id: option_1.id }
        }
      end

      expect(response.parsed_body["voting_data"]["votes_count"]).to eq(1)
      expect(user.poll_votes.size).to eq(1)
    end
  end
end