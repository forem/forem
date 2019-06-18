require "rails_helper"

RSpec.describe "PollSkips", type: :request do
  let(:user) { create(:user) }
  let(:article) { create(:article) }
  let(:poll) { create(:poll, article_id: article.id) }

  before { sign_in user }

  describe "POST /poll_votes" do
    it "votes on behalf of current user" do
      post "/poll_skips", params: {
        poll_skip: { poll_id: poll.id }
      }
      expect(JSON.parse(response.body)["voting_data"]["votes_count"]).to eq(0)
      expect(JSON.parse(response.body)["voting_data"]["votes_distribution"]).to include([poll.poll_options.first.id, 0])
      expect(JSON.parse(response.body)["poll_id"]).to eq(poll.id)
      expect(JSON.parse(response.body)["voted"]).to eq(false)
      expect(user.poll_skips.size).to eq(1)
    end
    it "only allows one of vote or skip" do
      post "/poll_skips", params: {
        poll_skip: { poll_id: poll.id }
      }
      post "/poll_votes", params: {
        poll_vote: { poll_option_id: poll.poll_options.first.id }
      }
      expect(user.poll_skips.size).to eq(1)
      expect(user.poll_votes.size).to eq(0)
    end
  end
end
