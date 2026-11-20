require "rails_helper"

RSpec.describe "Api::V1::Analytics" do
  let(:api_secret) { create(:api_secret, user: create(:user, :without_profile, profile_image: nil)) }
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

    it "fails with 422 when start is missing or has an incorrect format", :aggregate_failures do
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
      let(:user) { create(:user, :without_profile, profile_image: nil) }
      let(:v1_headers) { { "Accept" => "application/vnd.forem.api-v1+json" } }

      before { sign_in user }

      it "returns all five panels with no-store headers, defaults start to registration date, and validates dates",
         :aggregate_failures do
        allow(Rails.cache).to receive(:fetch).and_call_original

        get "/api/analytics/dashboard?start=2019-03-29", headers: v1_headers
        expect(response).to have_http_status(:ok)
        expect(response.headers["Cache-Control"]).to include("no-store")
        expect(response.parsed_body.keys).to match_array(
          %w[historical totals referrers top_contributors follower_engagement start_date_floor],
        )

        get "/api/analytics/dashboard?start=2019-03-29", headers: v1_headers
        expect(Rails.cache).not_to have_received(:fetch).with(
          a_string_starting_with("analytics-dashboard-v3-"),
          anything,
        )
        expect(Rails.cache).not_to have_received(:fetch).with(
          a_string_starting_with("analytics-for-dates-v3-"),
          anything,
        )

        get "/api/analytics/dashboard", headers: v1_headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["start_date_floor"]).to eq(user.registered_at.to_date.iso8601)

        get "/api/analytics/dashboard?start=2019/3/29", headers: v1_headers
        expect(response).to have_http_status(:unprocessable_entity)
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
          with_tags: false,
          with_main_image: false,
          past_published_at: user.registered_at - 2.years,
        )

        get "/api/analytics/dashboard?article_id=#{article.id}", headers: v1_headers

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["start_date_floor"]).to eq(article.published_at.to_date.iso8601)
      end

      it "loads ArticleActivity rows only once per dashboard request and returns all-time totals" do
        article = create(
          :article,
          :past,
          user: user,
          published: true,
          with_tags: false,
          with_main_image: false,
          past_published_at: Time.zone.parse("2019-01-01"),
        )
        ArticleActivity.create!(
          article: article,
          total_page_views: 150,
          daily_page_views: {
            "2019-01-10" => { "total" => 100, "sum_read_seconds" => 200, "logged_in_count" => 10 },
            "2019-03-30" => { "total" => 50, "sum_read_seconds" => 100, "logged_in_count" => 5 }
          },
          daily_reactions: {},
          daily_comments: { "2019-01-10" => 3, "2019-03-30" => 2 },
          daily_referrers: {},
        )

        activity_queries = 0
        callback = lambda do |*, payload|
          next if %w[SCHEMA TRANSACTION].include?(payload[:name])

          activity_queries += 1 if payload[:sql].include?('"article_activities"')
        end

        ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
          get "/api/analytics/dashboard?start=2019-03-29&end=2019-04-01&article_id=#{article.id}", headers: v1_headers
        end

        expect(response).to have_http_status(:ok)
        expect(activity_queries).to eq(1)
        body = response.parsed_body
        expect(body.dig("totals", "page_views", "total")).to eq(150)
        expect(body.dig("totals", "comments", "total")).to eq(5)
        expect(body.dig("historical", "2019-03-30", "page_views", "total")).to eq(50)
      end
    end
  end

  describe "GET /api/analytics/heatmap" do
    let(:user) { create(:user, :without_profile, profile_image: nil) }
    let(:v1_headers) { { "Accept" => "application/vnd.forem.api-v1+json" } }

    it "rejects unauthenticated requests and authenticates with a valid API key", :aggregate_failures do
      get "/api/analytics/heatmap", headers: v1_headers
      expect(response).to have_http_status(:unauthorized)

      api_secret = create(:api_secret, user: user)
      get "/api/analytics/heatmap", headers: v1_headers.merge("api-key" => api_secret.secret)
      expect(response).to have_http_status(:ok)
    end

    it "returns the expected JSON shape, honors the end param, and rejects malformed dates for a session user",
       :aggregate_failures do
      sign_in user
      get "/api/analytics/heatmap", headers: v1_headers

      expect(response).to have_http_status(:ok)
      expect(response.headers["Cache-Control"]).to eq("no-store")
      body = response.parsed_body
      expect(body.keys).to match_array(%w[start_date end_date days totals max])
      expect(body["days"].length).to eq(365)
      expect(body["totals"].keys).to match_array(%w[articles comments reactions total])

      get "/api/analytics/heatmap", params: { end: "2024-12-31" }, headers: v1_headers
      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["end_date"]).to eq("2024-12-31")
      expect(body["start_date"]).to eq("2024-01-02")

      get "/api/analytics/heatmap", params: { end: "not-a-date" }, headers: v1_headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
