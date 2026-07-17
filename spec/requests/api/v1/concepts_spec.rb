require "rails_helper"

RSpec.describe "Api::V1::Concepts", type: :request do
  let(:admin) { create(:user, :super_admin) }
  let(:user) { create(:user) }
  let(:embedding) { Array.new(768, 0.1) }
  let!(:concept_1) { create(:concept, anchor_embedding: embedding) }
  let!(:concept_2) { create(:concept, anchor_embedding: embedding) }
  let!(:metric_recent) { create(:concept_daily_metric, concept: concept_1, date: 2.days.ago.to_date) }
  let!(:metric_old) { create(:concept_daily_metric, concept: concept_1, date: 10.days.ago.to_date) }

  let(:admin_headers) do
    {
      "api-key" => create(:api_secret, user: admin).secret,
      "Accept" => "application/vnd.forem.api-v1+json"
    }
  end

  let(:user_headers) do
    {
      "api-key" => create(:api_secret, user: user).secret,
      "Accept" => "application/vnd.forem.api-v1+json"
    }
  end

  let(:guest_headers) do
    { "Accept" => "application/vnd.forem.api-v1+json" }
  end

  describe "Authentication" do
    it "returns 401 for guests" do
      get api_concepts_path, headers: guest_headers
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/concepts" do
    context "as a super admin" do
      it "returns a list of all concepts without leaking anchor_embeddings or max_lookback_days" do
        get api_concepts_path, headers: admin_headers
        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json.length).to eq(2)
        concept_ids = json.map { |c| c["id"] }
        expect(concept_ids).to include(concept_1.id, concept_2.id)

        concept_json = json.find { |c| c["id"] == concept_1.id }
        expect(concept_json).not_to have_key("anchor_embedding")
        expect(concept_json).to have_key("similarity_threshold")
        expect(concept_json).not_to have_key("max_lookback_days")
      end
    end

    context "as a regular user with access to some concepts" do
      before do
        create(:concept_access, user: user, concept: concept_1)
      end

      it "returns only the concepts the user has access to, with their recent daily metrics" do
        get api_concepts_path, headers: user_headers
        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json.length).to eq(1)
        concept_json = json[0]
        expect(concept_json["id"]).to eq(concept_1.id)
        expect(concept_json).to have_key("daily_metrics")

        # Default is 7 days, so should return metric_recent but not metric_old
        metric_dates = concept_json["daily_metrics"].map { |m| m["date"] }
        expect(metric_dates).to include(metric_recent.date.to_s)
        expect(metric_dates).not_to include(metric_old.date.to_s)
      end

      it "returns daily metrics for custom timeframe when days param is specified" do
        get api_concepts_path(days: 14), headers: user_headers
        expect(response).to be_successful
        json = JSON.parse(response.body)
        concept_json = json[0]

        metric_dates = concept_json["daily_metrics"].map { |m| m["date"] }
        expect(metric_dates).to include(metric_recent.date.to_s, metric_old.date.to_s)
      end
    end

    context "as a regular user with no concept accesses" do
      it "returns an empty list" do
        get api_concepts_path, headers: user_headers
        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json).to eq([])
      end
    end
  end

  describe "GET /api/concepts/:id" do
    context "as a super admin" do
      it "allows viewing any concept without leaking anchor_embedding or max_lookback_days" do
        get api_concept_path(concept_1), headers: admin_headers
        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json["id"]).to eq(concept_1.id)
        expect(json).not_to have_key("anchor_embedding")
        expect(json).to have_key("similarity_threshold")
        expect(json).not_to have_key("max_lookback_days")
      end
    end

    context "as a regular user with access" do
      before do
        create(:concept_access, user: user, concept: concept_1)
      end

      it "allows viewing the concept with recent daily metrics and without leaking sensitive fields" do
        get api_concept_path(concept_1), headers: user_headers
        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json["id"]).to eq(concept_1.id)
        expect(json).not_to have_key("anchor_embedding")
        expect(json).to have_key("similarity_threshold")
        expect(json).not_to have_key("max_lookback_days")
        expect(json).to have_key("daily_metrics")

        # Default is 7 days, so should return metric_recent but not metric_old
        metric_dates = json["daily_metrics"].map { |m| m["date"] }
        expect(metric_dates).to include(metric_recent.date.to_s)
        expect(metric_dates).not_to include(metric_old.date.to_s)
      end

      it "allows viewing the concept with daily metrics for custom timeframe when days param is specified" do
        get api_concept_path(concept_1, days: 14), headers: user_headers
        expect(response).to be_successful
        json = JSON.parse(response.body)

        metric_dates = json["daily_metrics"].map { |m| m["date"] }
        expect(metric_dates).to include(metric_recent.date.to_s, metric_old.date.to_s)
      end

      it "denies viewing other concepts" do
        get api_concept_path(concept_2), headers: user_headers
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "as a regular user without access" do
      it "denies viewing the concept" do
        get api_concept_path(concept_1), headers: user_headers
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "PATCH /api/concepts/:id" do
    let(:valid_params) { { concept: { score: 5.5, description: "Updated description via API", similarity_threshold: 0.45 } } }

    before do
      allow_any_instance_of(Concepts::AnchorGenerator).to receive(:call)
      allow(Concepts::BackfillClassifierWorker).to receive(:perform_async)
    end

    context "as a super admin" do
      it "allows updating the concept" do
        patch api_concept_path(concept_1), params: valid_params, headers: admin_headers
        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json["score"]).to eq(5.5)
        expect(json["description"]).to eq("Updated description via API")
        expect(json["similarity_threshold"]).to eq(0.45)
        expect(concept_1.reload.score).to eq(5.5)
        expect(concept_1.reload.description).to eq("Updated description via API")
        expect(concept_1.reload.similarity_threshold).to eq(0.45)
        expect(Concepts::BackfillClassifierWorker).to have_received(:perform_async).with(concept_1.id)
      end
    end

    context "as a regular user with access" do
      before do
        create(:concept_access, user: user, concept: concept_1)
      end

      it "allows updating score, description, and similarity_threshold" do
        patch api_concept_path(concept_1), params: valid_params, headers: user_headers
        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json["score"]).to eq(5.5)
        expect(json["description"]).to eq("Updated description via API")
        expect(json["similarity_threshold"]).to eq(0.45)
        expect(concept_1.reload.score).to eq(5.5)
        expect(concept_1.reload.description).to eq("Updated description via API")
        expect(concept_1.reload.similarity_threshold).to eq(0.45)
        expect(Concepts::BackfillClassifierWorker).to have_received(:perform_async).with(concept_1.id)
      end

      it "denies updating other concepts" do
        patch api_concept_path(concept_2), params: valid_params, headers: user_headers
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "as a regular user without access" do
      it "denies updating" do
        patch api_concept_path(concept_1), params: valid_params, headers: user_headers
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /api/concepts/:id/articles" do
    let!(:article_low) { create(:article, score: 10, published: true) }
    let!(:article_high) { create(:article, score: 100, published: true) }
    let!(:membership_low) { create(:concept_membership, concept: concept_1, record: article_low, distance: 0.1) }
    let!(:membership_high) { create(:concept_membership, concept: concept_1, record: article_high, distance: 0.9) }

    context "as a regular user with access" do
      before do
        create(:concept_access, user: user, concept: concept_1)
      end

      it "returns mapped articles" do
        get articles_api_concept_path(concept_1), headers: user_headers
        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json.length).to eq(2)
      end

      it "orders articles by distance by default" do
        get articles_api_concept_path(concept_1), headers: user_headers
        json = JSON.parse(response.body)
        expect(json[0]["id"]).to eq(article_low.id)
        expect(json[1]["id"]).to eq(article_high.id)
      end

      it "orders articles by score DESC when sort=score is specified" do
        get articles_api_concept_path(concept_1, sort: "score"), headers: user_headers
        json = JSON.parse(response.body)
        expect(json[0]["id"]).to eq(article_high.id)
        expect(json[1]["id"]).to eq(article_low.id)
      end
    end

    context "as a regular user without access" do
      it "denies access" do
        get articles_api_concept_path(concept_1), headers: user_headers
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "Article unpublishing cleanup" do
    let!(:article) { create(:article, score: 50, published: true) }
    let!(:trend) { create(:trend) }
    let!(:concept_membership) { create(:concept_membership, concept: concept_1, record: article, distance: 0.1) }
    let!(:trend_membership) { create(:trend_membership, trend: trend, article: article, distance: 0.1) }

    it "destroys memberships and decrements count when the article is unpublished" do
      expect(concept_1.concept_memberships.count).to eq(1)
      expect(trend.trend_memberships.count).to eq(1)
      expect(trend.reload.articles_count).to eq(1)

      Articles::Unpublish.call(article.user, article)

      expect(concept_1.concept_memberships.count).to eq(0)
      expect(trend.trend_memberships.count).to eq(0)
      expect(trend.reload.articles_count).to eq(0)
    end
  end

  describe "GET /api/concepts/search" do
    let(:query_embedding) { [1.0] + Array.new(767, 0.0) }

    before do
      allow_any_instance_of(Ai::Embedding).to receive(:call).and_return(query_embedding)
    end

    it "requires api-key" do
      get search_api_concepts_path, headers: guest_headers
      expect(response).to have_http_status(:unauthorized)
    end

    it "requires q parameter" do
      get search_api_concepts_path, headers: admin_headers
      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)["error"]).to eq("q parameter is required")
    end

    context "as a super admin" do
      it "returns matching concepts with distance and similarity metrics" do
        get search_api_concepts_path(q: "databases"), headers: admin_headers
        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json.length).to eq(2)
        expect(json[0]).to have_key("distance")
        expect(json[0]).to have_key("similarity")
      end
    end

    context "as a regular user with access to one concept" do
      before do
        create(:concept_access, user: user, concept: concept_1)
      end

      it "returns only accessible matching concepts" do
        get search_api_concepts_path(q: "databases"), headers: user_headers
        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json.length).to eq(1)
        expect(json[0]["id"]).to eq(concept_1.id)
      end

      it "respects similarity threshold param" do
        get search_api_concepts_path(q: "databases", threshold: 0.001), headers: user_headers
        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json).to eq([])
      end
    end
  end
end
