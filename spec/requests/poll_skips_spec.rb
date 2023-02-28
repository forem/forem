require "rails_helper"

RSpec.describe "PollSkips" do
  let(:user) { create(:user) }
  let(:article) { create(:article) }
  let(:poll) { create(:poll, article_id: article.id) }

  before { sign_in user }

  describe "POST /poll_skips" do
    it "votes on behalf of current user" do
      post "/poll_skips", params: { poll_skip: { poll_id: poll.id } }

      json = response.parsed_body

      expect(json["voting_data"]["votes_count"]).to eq(0)
      expect(json["voting_data"]["votes_distribution"]).to include([poll.poll_options.first.id, 0])
      expect(json["poll_id"]).to eq(poll.id)
      expect(json["voted"]).to be(false)
      expect(user.poll_skips.size).to eq(1)
    end

    it "only allows one of vote or skip" do
      post "/poll_skips", params: { poll_skip: { poll_id: poll.id } }
      post "/poll_votes", params: { poll_vote: { poll_option_id: poll.poll_options.first.id } }

      expect(user.poll_skips.size).to eq(1)
      expect(user.poll_votes.size).to eq(0)
    end

    it "does not allow two skips" do
      expect do
        post "/poll_skips", params: { poll_skip: { poll_id: poll.id } }
        post "/poll_skips", params: { poll_skip: { poll_id: poll.id } }
      end.to change(user.poll_skips, :count).by(1)
    end
  end
end
