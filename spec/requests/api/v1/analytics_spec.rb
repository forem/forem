require "rails_helper"

RSpec.describe "Api::V1::Analytics" do
  let(:api_secret) { create(:api_secret) }
  let(:headers) { { "Accept" => "application/vnd.forem.api-v1+json", "api-key" => api_secret.secret } }

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
        expect(response.parsed_body["error"]).to eq(error_message)
      end
    end

    context "when the start parameter has the incorrect format" do
      before { get "/api/analytics/historical?start=2019/2/2", headers: headers }

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

  describe "GET /api/analytics/top_contributors" do
    include_examples "GET /api/analytics/:endpoint authorization examples", "top_contributors"

    it "returns 401 when unauthenticated" do
      get "/api/analytics/top_contributors", headers: { "Accept" => "application/vnd.forem.api-v1+json" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/analytics/follower_engagement" do
    include_examples "GET /api/analytics/:endpoint authorization examples", "follower_engagement"

    it "returns 401 when unauthenticated" do
      get "/api/analytics/follower_engagement", headers: { "Accept" => "application/vnd.forem.api-v1+json" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/analytics/dashboard" do
    include_examples "GET /api/analytics/:endpoint authorization examples", "dashboard", "&start=2019-03-29"

    it "returns 401 when unauthenticated" do
      get "/api/analytics/dashboard", headers: { "Accept" => "application/vnd.forem.api-v1+json" }
      expect(response).to have_http_status(:unauthorized)
    end

    context "when authenticated" do
      let(:user) { create(:user) }
      let(:v1_headers) { { "Accept" => "application/vnd.forem.api-v1+json" } }

      before { sign_in user }

      it "returns all five panels in a single response" do
        get "/api/analytics/dashboard?start=2019-03-29", headers: v1_headers

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.keys).to match_array(
          %w[historical totals referrers top_contributors follower_engagement start_date_floor],
        )
      end

      it "defaults start to the owner registration date when omitted" do
        get "/api/analytics/dashboard", headers: v1_headers

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["start_date_floor"]).to eq(user.registered_at.to_date.iso8601)
      end

      it "uses the article's published_at as start_date_floor when article_id is set" do
        # Cross-post case: article was published before the owner's account
        # existed, so the owner-registration floor would silently chop off
        # pre-account activity. The endpoint must surface the article's own
        # publish date instead.
        article = create(
          :article,
          :past,
          user: user,
          published: true,
          past_published_at: user.registered_at - 2.years,
        )

        get "/api/analytics/dashboard?article_id=#{article.id}", headers: v1_headers

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["start_date_floor"]).to eq(article.published_at.to_date.iso8601)
      end

      it "rejects requests with malformed date parameters" do
        get "/api/analytics/dashboard?start=2019/3/29", headers: v1_headers

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "sets a no-store Cache-Control header so the dashboard always reflects fresh activity" do
        get "/api/analytics/dashboard?start=2019-03-29", headers: v1_headers

        expect(response.headers["Cache-Control"]).to include("no-store")
      end

      it "does not server-side memoize the dashboard payload (always reads live from ArticleActivity)" do
        allow(Rails.cache).to receive(:fetch).and_call_original

        get "/api/analytics/dashboard?start=2019-03-29", headers: v1_headers
        get "/api/analytics/dashboard?start=2019-03-29", headers: v1_headers

        expect(Rails.cache).not_to have_received(:fetch).with(
          a_string_starting_with("analytics-dashboard-v3-"),
          anything,
        )
        expect(Rails.cache).not_to have_received(:fetch).with(
          a_string_starting_with("analytics-for-dates-v3-"),
          anything,
        )
      end
    end
  end
end
