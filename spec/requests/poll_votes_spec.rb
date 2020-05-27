require "rails_helper"

RSpec.describe "PollVotes", type: :request do
  let(:user) { create(:user) }
  let(:article) { create(:article) }
  let(:poll) { create(:poll, article_id: article.id) }

  before { sign_in user }

  describe "GET /poll_votes" do
    xit "returns proper results for poll" do
      get "/poll_votes/#{poll.id}"
      expect(JSON.parse(response.body)["voting_data"]["votes_count"]).to eq(0)
      expect(JSON.parse(response.body)["voting_data"]["votes_distribution"]).to include([poll.poll_options.first.id, 0])
      expect(JSON.parse(response.body)["poll_id"]).to eq(poll.id)
      expect(JSON.parse(response.body)["voted"]).to eq(false)
    end

    xit "returns proper results for poll if voted" do
      create(:poll_vote, user_id: user.id, poll_option_id: poll.poll_options.first.id, poll_id: poll.id)
      get "/poll_votes/#{poll.id}"
      expect(JSON.parse(response.body)["voting_data"]["votes_count"]).to eq(1)
      expect(JSON.parse(response.body)["voting_data"]["votes_distribution"]).to include([poll.poll_options.first.id, 1])
      expect(JSON.parse(response.body)["poll_id"]).to eq(poll.id)
      expect(JSON.parse(response.body)["voted"]).to eq(true)
    end
  end

  describe "POST /poll_votes" do
    xit "votes on behalf of current user" do
      post "/poll_votes", params: {
        poll_vote: { poll_option_id: poll.poll_options.first.id }
      }
      expect(JSON.parse(response.body)["voting_data"]["votes_count"]).to eq(1)
      expect(JSON.parse(response.body)["voting_data"]["votes_distribution"]).to include([poll.poll_options.first.id, 1])
      expect(JSON.parse(response.body)["poll_id"]).to eq(poll.id)
      expect(JSON.parse(response.body)["voted"]).to eq(true)
      expect(user.poll_votes.size).to eq(1)
    end

    xit "votes on behalf of current user only once" do
      post "/poll_votes", params: {
        poll_vote: { poll_option_id: poll.poll_options.first.id }
      }
      post "/poll_votes", params: {
        poll_vote: { poll_option_id: poll.poll_options.first.id }
      }
      expect(JSON.parse(response.body)["voting_data"]["votes_count"]).to eq(1)
      expect(JSON.parse(response.body)["voting_data"]["votes_distribution"]).to include([poll.poll_options.first.id, 1])
      expect(JSON.parse(response.body)["voted"]).to eq(true)
      expect(user.poll_votes.size).to eq(1)
    end
  end
end
