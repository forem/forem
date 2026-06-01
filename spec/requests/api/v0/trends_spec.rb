require "rails_helper"

RSpec.describe "Api::V0::Trends" do
  let!(:trend1) { create(:trend, name: "Ruby 3.4", score: 10, first_observed_at: 1.day.ago, last_observed_at: Time.current) }
  let!(:trend2) { create(:trend, name: "AI Agents", score: 20, first_observed_at: 2.days.ago, last_observed_at: Time.current) }

  describe "GET /api/trends" do
    it "returns list of hot and recent trends" do
      get "/api/trends"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(2)
      
      # Ordered by score: desc (AI Agents first, then Ruby 3.4)
      expect(response.parsed_body.first["name"]).to eq("AI Agents")
      expect(response.parsed_body.last["name"]).to eq("Ruby 3.4")
    end

    it "returns trends with correct json structure" do
      get "/api/trends"

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
      get "/api/trends", params: { page: 1, per_page: 1 }
      expect(response.parsed_body.size).to eq(1)
      expect(response.parsed_body.first["name"]).to eq("AI Agents")

      get "/api/trends", params: { page: 2, per_page: 1 }
      expect(response.parsed_body.size).to eq(1)
      expect(response.parsed_body.first["name"]).to eq("Ruby 3.4")
    end

    it "sets correct surrogate keys" do
      get "/api/trends"

      expected_keys = ["trends", trend1.record_key, trend2.record_key].to_set
      expect(response.headers["surrogate-key"].split.to_set).to eq(expected_keys)
    end
  end

  describe "GET /api/trends/:id_or_slug" do
    it "finds trend by ID" do
      get "/api/trends/#{trend1.id}"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["name"]).to eq("Ruby 3.4")
      expect(response.headers["surrogate-key"]).to eq(trend1.record_key)
    end

    it "finds trend by Slug" do
      get "/api/trends/#{trend2.slug}"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["name"]).to eq("AI Agents")
    end

    it "returns 404 for non-existent trend" do
      get "/api/trends/does-not-exist"

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
      get "/api/trends/#{trend2.slug}/articles"

      expect(response).to have_http_status(:ok)
      # Two articles in trend2
      expect(response.parsed_body.size).to eq(2)
      expect(response.parsed_body.first["title"]).to eq("AI agents are taking over")
      expect(response.parsed_body.last["title"]).to eq("Building my first AI agent")
    end

    it "returns articles in a trend by ID" do
      get "/api/trends/#{trend2.id}/articles"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(2)
    end

    it "supports pagination for articles" do
      get "/api/trends/#{trend2.slug}/articles", params: { page: 1, per_page: 1 }
      expect(response.parsed_body.size).to eq(1)
      expect(response.parsed_body.first["title"]).to eq("AI agents are taking over")
    end

    it "sets correct surrogate keys for articles list" do
      get "/api/trends/#{trend2.slug}/articles"

      expected_keys = [trend2.record_key, article1.record_key, article2.record_key].to_set
      expect(response.headers["surrogate-key"].split.to_set).to eq(expected_keys)
    end

    it "returns 404 if trend is not found" do
      get "/api/trends/does-not-exist/articles"

      expect(response).to have_http_status(:not_found)
    end
  end
end
