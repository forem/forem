require "rails_helper"

RSpec.describe "Api::V1::Trends" do
  let(:headers) { { "Accept" => "application/vnd.forem.api-v1+json" } }
  let!(:trend1) { create(:trend, name: "Ruby 3.4", score: 10, first_observed_at: 1.day.ago, last_observed_at: Time.current) }
  let!(:trend2) { create(:trend, name: "AI Agents", score: 20, first_observed_at: 2.days.ago, last_observed_at: Time.current) }

  describe "GET /api/trends" do
    it "returns list of hot and recent trends" do
      get "/api/trends", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(2)
      
      # Ordered by score: desc (AI Agents first, then Ruby 3.4)
      expect(response.parsed_body.first["name"]).to eq("AI Agents")
      expect(response.parsed_body.last["name"]).to eq("Ruby 3.4")
    end

    it "returns trends with correct json structure" do
      get "/api/trends", headers: headers

      trend_json = response.parsed_body.first
      expect(trend_json.keys).to match_array(%w[
        type_of id name slug description key_questions score articles_count
        cover_image first_observed_at last_observed_at created_at updated_at
      ])
      expect(trend_json["type_of"]).to eq("trend")
      expect(trend_json["name"]).to eq("AI Agents")
      expect(trend_json["score"]).to eq(20.0)
    end

    it "supports pagination" do
      get "/api/trends", params: { page: 1, per_page: 1 }, headers: headers
      expect(response.parsed_body.size).to eq(1)
      expect(response.parsed_body.first["name"]).to eq("AI Agents")

      get "/api/trends", params: { page: 2, per_page: 1 }, headers: headers
      expect(response.parsed_body.size).to eq(1)
      expect(response.parsed_body.first["name"]).to eq("Ruby 3.4")
    end

    it "sets correct surrogate keys" do
      get "/api/trends", headers: headers

      expected_keys = ["trends", trend1.record_key, trend2.record_key].to_set
      expect(response.headers["surrogate-key"].split.to_set).to eq(expected_keys)
    end
  end

  describe "GET /api/trends/:id_or_slug" do
    it "finds trend by ID" do
      get "/api/trends/#{trend1.id}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["name"]).to eq("Ruby 3.4")
      expect(response.headers["surrogate-key"]).to eq(trend1.record_key)
    end

    it "finds trend by Slug and returns top_articles" do
      get "/api/trends/#{trend2.slug}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["name"]).to eq("AI Agents")
      expect(response.parsed_body).to have_key("top_articles")
    end

    it "returns 404 for non-existent trend" do
      get "/api/trends/does-not-exist", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/trends/:trend_id_or_slug/articles" do
    let!(:article1) { create(:article, published: true, title: "AI agents are taking over", score: 100) }
    let!(:article2) { create(:article, published: true, title: "Building my first AI agent", score: 50) }
    let!(:article3) { create(:article, published: true, title: "Ruby 3.4 patterns", score: 10) }

    before do
      create(:trend_membership, trend: trend2, article: article1, distance: 0.1)
      create(:trend_membership, trend: trend2, article: article2, distance: 0.2)
      create(:trend_membership, trend: trend1, article: article3, distance: 0.05)
    end

    it "returns articles in a trend ordered by proximity distance" do
      get "/api/trends/#{trend2.slug}/articles", headers: headers

      expect(response).to have_http_status(:ok)
      # Two articles in trend2
      expect(response.parsed_body.size).to eq(2)
      expect(response.parsed_body.first["title"]).to eq("AI agents are taking over")
      expect(response.parsed_body.last["title"]).to eq("Building my first AI agent")
    end

    it "returns articles in a trend by ID" do
      get "/api/trends/#{trend2.id}/articles", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(2)
    end

    it "supports pagination for articles" do
      get "/api/trends/#{trend2.slug}/articles", params: { page: 1, per_page: 1 }, headers: headers
      expect(response.parsed_body.size).to eq(1)
      expect(response.parsed_body.first["title"]).to eq("AI agents are taking over")
    end

    it "sets correct surrogate keys for articles list" do
      get "/api/trends/#{trend2.slug}/articles", headers: headers

      expected_keys = [trend2.record_key, article1.record_key, article2.record_key].to_set
      expect(response.headers["surrogate-key"].split.to_set).to eq(expected_keys)
    end

    it "orders articles by score DESC when sort=score is specified" do
      # Let's make the high distance one have a higher score, and low distance have a lower score to differentiate
      # distance order (article1 = 0.1, score = 100 vs article2 = 0.2, score = 50)
      # Let's adjust article2 score to 150
      article2.update!(score: 150)
      get "/api/trends/#{trend2.slug}/articles", params: { sort: "score" }, headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.first["title"]).to eq("Building my first AI agent") # score 150
      expect(response.parsed_body.last["title"]).to eq("AI agents are taking over")    # score 100
    end

    it "returns 404 if trend is not found" do
      get "/api/trends/does-not-exist/articles", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
