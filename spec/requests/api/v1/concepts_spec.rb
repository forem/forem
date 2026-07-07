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
      it "returns a list of all concepts without leaking anchor_embeddings, similarity_threshold, or max_lookback_days" do
        get api_concepts_path, headers: admin_headers
        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json.length).to eq(2)
        concept_ids = json.map { |c| c["id"] }
        expect(concept_ids).to include(concept_1.id, concept_2.id)

        concept_json = json.find { |c| c["id"] == concept_1.id }
        expect(concept_json).not_to have_key("anchor_embedding")
        expect(concept_json).not_to have_key("similarity_threshold")
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
      it "allows viewing any concept without leaking anchor_embedding, similarity_threshold, or max_lookback_days" do
        get api_concept_path(concept_1), headers: admin_headers
        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json["id"]).to eq(concept_1.id)
        expect(json).not_to have_key("anchor_embedding")
        expect(json).not_to have_key("similarity_threshold")
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
        expect(json).not_to have_key("similarity_threshold")
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
end
