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

    it "does not allow two skips" do
      expect do
        post "/poll_skips", params: { poll_skip: { poll_id: poll.id } }
        post "/poll_skips", params: { poll_skip: { poll_id: poll.id } }
      end.to change(user.poll_skips, :count).by(1)
    end

    it "does not raise or report an error when skipping a survey poll twice in the same session" do
      survey = create(:survey)
      survey_poll = create(:poll, survey: survey)
      allow(Rails.error).to receive(:report)

      expect do
        post "/poll_skips", params: { poll_skip: { poll_id: survey_poll.id, session_start: 1 } }
        post "/poll_skips", params: { poll_skip: { poll_id: survey_poll.id, session_start: 1 } }
      end.to change(user.poll_skips, :count).by(1)

      expect(Rails.error).not_to have_received(:report)
    end
  end
end
