require "rails_helper"

RSpec.describe "Api::V0::Analytics" do
  describe "GET /api/analytics/totals" do
    include_examples "GET /api/analytics/:endpoint authorization examples", "totals"
  end

  describe "GET /api/analytics/historical" do
    include_examples "GET /api/analytics/:endpoint authorization examples", "historical", "&start=2019-03-29"

    it "fails with 422 when start is missing or has an incorrect format", :aggregate_failures do
      headers = { "api-key" => api_token.secret }

      get "/api/analytics/historical", headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to eq("Required 'start' parameter is missing")

      get "/api/analytics/historical?start=2019/2/2", headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to eq(
        "Date parameters 'start' or 'end' must be in the format of 'yyyy-mm-dd'",
      )
    end
  end

  describe "GET /api/analytics/past_day" do
    include_examples "GET /api/analytics/:endpoint authorization examples", "past_day"
  end

  describe "GET /api/analytics/referrers" do
    include_examples "GET /api/analytics/:endpoint authorization examples", "referrers"
  end

  describe "GET /api/analytics/top_contributors" do
    include_examples "GET /api/analytics/:endpoint authorization examples", "top_contributors"
  end

  describe "GET /api/analytics/follower_engagement" do
    include_examples "GET /api/analytics/:endpoint authorization examples", "follower_engagement"
  end

  describe "GET /api/analytics/dashboard" do
    include_examples "GET /api/analytics/:endpoint authorization examples", "dashboard", "&start=2019-03-29"
  end
end
