require "rails_helper"

RSpec.describe "Follows #create" do
  let(:current_user) { create(:user) }
  let(:user) { create(:user) }
  let(:headers) { { "Content-Type": "application/json", Accept: "application/json" } }
  let(:follow_payload) do
    {
      followable_type: "User",
      followable_id: user.id,
      verb: "follow"
    }.to_json
  end

  before do
    sign_in current_user
    Settings::RateLimit.clear_cache
  end

  context "when rate limit has been hit" do
    before do
      rate_limit_checker = RateLimitChecker.new(current_user)

      allow(rate_limit_checker)
        .to receive(:user_today_follow_count)
        .and_return(Settings::RateLimit.follow_count_daily + 1)

      allow(RateLimitChecker)
        .to receive(:new)
        .and_return(rate_limit_checker)
    end

    it "returns an error for too many follows in a day" do
      post "/follows", headers: headers, params: follow_payload
      json_response = JSON.parse(response.body)

      expect(response).to have_http_status(:too_many_requests)
      expect(json_response["error"]).to eq("Daily account follow limit reached!")
    end
  end

  it "follows" do
    post "/follows", headers: headers, params: follow_payload

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)["outcome"]).to eq("followed")
  end

  it "unfollows" do
    current_user.follow(user)
    post "/follows", headers: headers,
                     params: { followable_type: "User", followable_id: user.id, verb: "unfollow" }.to_json

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)["outcome"]).to eq("unfollowed")
  end
end
