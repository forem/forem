require "rails_helper"

RSpec.describe "Api::V1::Admin::Concepts", type: :request do
  let(:admin) { create(:user, :super_admin) }
  let(:user) { create(:user) }
  let(:embedding) { Array.new(768, 0.1) }
  let!(:concept) { create(:concept, anchor_embedding: embedding) }

  let(:headers) do
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

  describe "Authentication" do
    let(:guest_headers) do
      { "Accept" => "application/vnd.forem.api-v1+json" }
    end

    it "returns 401 for guests" do
      get api_admin_concepts_path, headers: guest_headers
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 for normal users" do
      get api_admin_concepts_path, headers: user_headers
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/admin/concepts" do
    it "returns a list of concepts" do
      get api_admin_concepts_path, headers: headers
      expect(response).to be_successful
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json[0]["name"]).to eq(concept.name)
    end
  end

  describe "GET /api/admin/concepts/:id" do
    it "returns the requested concept" do
      get api_admin_concept_path(concept), headers: headers
      expect(response).to be_successful
      json = JSON.parse(response.body)
      expect(json["id"]).to eq(concept.id)
      expect(json["name"]).to eq(concept.name)
    end
  end

  describe "POST /api/admin/concepts" do
    before do
      allow_any_instance_of(Concepts::AnchorGenerator).to receive(:call) do |generator|
        concept_instance = generator.instance_variable_get(:@concept)
        concept_instance.anchor_embedding = embedding
        concept_instance.description = "Synthetic description" if concept_instance.description.blank?
      end
      allow(Concepts::BackfillClassifierWorker).to receive(:perform_async)
    end

    context "with valid parameters" do
      it "creates a new Concept and enqueues backfill" do
        expect {
          post api_admin_concepts_path, params: { concept: { name: "New Concept", description: "Testing", similarity_threshold: 0.8 } }, headers: headers
        }.to change(Concept, :count).by(1)

        expect(response).to have_http_status(:created)
        new_concept = Concept.find_by(name: "New Concept")
        expect(Concepts::BackfillClassifierWorker).to have_received(:perform_async).with(new_concept.id)
      end

      it "ignores max_lookback_days and sets it to default" do
        post api_admin_concepts_path, params: { concept: { name: "Another Concept", max_lookback_days: 99 } }, headers: headers
        new_concept = Concept.find_by(name: "Another Concept")
        expect(new_concept.max_lookback_days).to eq(0)
      end
    end

    context "with invalid parameters" do
      it "does not create and returns errors" do
        expect {
          post api_admin_concepts_path, params: { concept: { name: "" } }, headers: headers
        }.to change(Concept, :count).by(0)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH /api/admin/concepts/:id" do
    before do
      allow_any_instance_of(Concepts::AnchorGenerator).to receive(:call)
      allow(Concepts::BackfillClassifierWorker).to receive(:perform_async)
    end

    context "with valid parameters" do
      it "updates the concept and enqueues backfill" do
        patch api_admin_concept_path(concept), params: { concept: { name: "Updated Concept Name" } }, headers: headers
        expect(response).to be_successful
        expect(concept.reload.name).to eq("Updated Concept Name")
        expect(Concepts::BackfillClassifierWorker).to have_received(:perform_async).with(concept.id)
      end

      it "does not update max_lookback_days" do
        expect {
          patch api_admin_concept_path(concept), params: { concept: { max_lookback_days: 99 } }, headers: headers
        }.not_to change { concept.reload.max_lookback_days }
      end
    end

    context "with invalid parameters" do
      it "does not update and returns errors" do
        patch api_admin_concept_path(concept), params: { concept: { name: "" } }, headers: headers
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /api/admin/concepts/:id" do
    it "destroys the concept" do
      expect {
        delete api_admin_concept_path(concept), headers: headers
      }.to change(Concept, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end

  describe "POST /api/admin/concepts/:id/trigger_lookback" do
    before do
      allow(Concepts::LookbackWorker).to receive(:perform_async)
    end

    context "with valid days" do
      it "enqueues the LookbackWorker" do
        post trigger_lookback_api_admin_concept_path(concept), params: { days: 40 }, headers: headers
        expect(response).to be_successful
        expect(Concepts::LookbackWorker).to have_received(:perform_async).with(concept.id, 40)
      end
    end

    context "with invalid days" do
      it "does not enqueue and returns 422" do
        post trigger_lookback_api_admin_concept_path(concept), params: { days: -10 }, headers: headers
        expect(response).to have_http_status(:unprocessable_entity)
        expect(Concepts::LookbackWorker).not_to have_received(:perform_async)
      end

      it "does not enqueue when requested days is less than or equal to max_lookback_days" do
        concept.update!(max_lookback_days: 40)
        post trigger_lookback_api_admin_concept_path(concept), params: { days: 30 }, headers: headers
        expect(response).to have_http_status(:unprocessable_entity)
        expect(Concepts::LookbackWorker).not_to have_received(:perform_async)
      end
    end
  end
end
