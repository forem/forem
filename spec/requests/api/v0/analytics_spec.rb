require "rails_helper"

RSpec.describe "Api::V0::Analytics" do
  describe "GET /api/analytics/totals" do
    include_examples "GET /api/analytics/:endpoint authorization examples", "totals"
  end

  describe "GET /api/analytics/historical" do
    include_examples "GET /api/analytics/:endpoint authorization examples", "historical", "&start=2019-03-29"

    context "when the start parameter is not included" do
      before { get "/api/analytics/historical", headers: { "api-key" => api_token.secret } }

      it "fails with an unprocessable entity HTTP error" do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "renders the proper error message in JSON" do
        error_message = "Required 'start' parameter is missing"
        expect(response.parsed_body["error"]).to eq(error_message)
      end
    end

    context "when the start parameter has the incorrect format" do
      before { get "/api/analytics/historical?start=2019/2/2", headers: { "api-key" => api_token.secret } }

      it "fails with an unprocessable entity HTTP error" do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "renders the proper error message in JSON" do
        error_message = "Date parameters 'start' or 'end' must be in the format of 'yyyy-mm-dd'"
        expect(response.parsed_body["error"]).to eq(error_message)
      end
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

    context "when start and end date parameters are provided" do
      let(:user) { create(:user) }
      let(:api_secret) { create(:api_secret, user: user) }

      it "returns a successful response with date-scoped data" do
        get "/api/analytics/dashboard?start=2024-01-01&end=2024-01-10", headers: { "api-key" => api_secret.secret }
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include("historical", "totals", "referrers", "top_contributors", "follower_engagement")
      end
    end
  end
end
