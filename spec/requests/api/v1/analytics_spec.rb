require "rails_helper"

RSpec.describe "Api::V1::Analytics", type: :request do
  let(:api_secret) { create(:api_secret) }
  let(:headers) { { "Accept" => "application/vnd.forem.api-v1+json", "api-key" => api_secret.secret } }

  before { allow(FeatureFlag).to receive(:enabled?).with(:api_v1).and_return(true) }

  describe "GET /api/analytics/totals" do
    include_examples "GET /api/analytics/:endpoint authorization examples", "totals"
  end

  describe "GET /api/analytics/historical" do
    include_examples "GET /api/analytics/:endpoint authorization examples", "historical", "&start=2019-03-29"

    it "returns 401 when unauthenticated" do
      get "/api/analytics/historical", headers: { "Accept" => "application/vnd.forem.api-v1+json" }
      expect(response).to have_http_status(:unauthorized)
    end

    context "when the start parameter is not included" do
      before { get "/api/analytics/historical", headers: headers }

      it "fails with an unprocessable entity HTTP error" do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "renders the proper error message in JSON" do
        error_message = "Required 'start' parameter is missing"
        expect(JSON.parse(response.body)["error"]).to eq(error_message)
      end
    end

    context "when the start parameter has the incorrect format" do
      before { get "/api/analytics/historical?start=2019/2/2", headers: headers }

      it "fails with an unprocessable entity HTTP error" do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "renders the proper error message in JSON" do
        error_message = "Date parameters 'start' or 'end' must be in the format of 'yyyy-mm-dd'"
        expect(JSON.parse(response.body)["error"]).to eq(error_message)
      end
    end
  end

  describe "GET /api/analytics/past_day" do
    include_examples "GET /api/analytics/:endpoint authorization examples", "past_day"

    it "returns 401 when unauthenticated" do
      get "/api/analytics/past_day", headers: { "Accept" => "application/vnd.forem.api-v1+json" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/analytics/referrers" do
    include_examples "GET /api/analytics/:endpoint authorization examples", "referrers"

    it "returns 401 when unauthenticated" do
      get "/api/analytics/referrers", headers: { "Accept" => "application/vnd.forem.api-v1+json" }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
