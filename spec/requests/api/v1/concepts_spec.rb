require "rails_helper"

RSpec.describe "Api::V1::Concepts", type: :request do
  let(:admin) { create(:user, :super_admin) }
  let(:user) { create(:user) }
  let(:embedding) { Array.new(768, 0.1) }
  let!(:concept_1) { create(:concept, anchor_embedding: embedding) }
  let!(:concept_2) { create(:concept, anchor_embedding: embedding) }

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
      it "returns a list of all concepts without leaking anchor_embeddings" do
        get api_concepts_path, headers: admin_headers
        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json.length).to eq(2)
        concept_ids = json.map { |c| c["id"] }
        expect(concept_ids).to include(concept_1.id, concept_2.id)
        expect(json[0]).not_to have_key("anchor_embedding")
      end
    end

    context "as a regular user with access to some concepts" do
      before do
        create(:concept_access, user: user, concept: concept_1)
      end

      it "returns only the concepts the user has access to" do
        get api_concepts_path, headers: user_headers
        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json.length).to eq(1)
        expect(json[0]["id"]).to eq(concept_1.id)
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
      it "allows viewing any concept without leaking anchor_embedding" do
        get api_concept_path(concept_1), headers: admin_headers
        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json["id"]).to eq(concept_1.id)
        expect(json).not_to have_key("anchor_embedding")
      end
    end

    context "as a regular user with access" do
      before do
        create(:concept_access, user: user, concept: concept_1)
      end

      it "allows viewing the concept without leaking anchor_embedding" do
        get api_concept_path(concept_1), headers: user_headers
        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json["id"]).to eq(concept_1.id)
        expect(json).not_to have_key("anchor_embedding")
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
