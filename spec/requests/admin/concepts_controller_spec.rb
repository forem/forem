require "rails_helper"
require "requests/shared_examples/internal_policy_dependant_request"

RSpec.describe "Admin::ConceptsController", type: :request do
  let(:admin) { create(:user, :super_admin) }
  let(:embedding) { Array.new(768, 0.1) }
  let!(:concept) { create(:concept, anchor_embedding: embedding) }

  it_behaves_like "an InternalPolicy dependant request", Concept do
    let(:request) { get admin_concepts_path }
  end

  describe "GET /admin/content_manager/concepts" do
    before { sign_in admin }

    it "returns a successful response" do
      get admin_concepts_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /admin/content_manager/concepts/:id" do
    before { sign_in admin }

    let!(:membership) { create(:concept_membership, concept: concept) }
    let!(:daily_metric) { create(:concept_daily_metric, concept: concept) }

    it "returns a successful response and renders details, chart, and memberships" do
      get admin_concept_path(concept)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(concept.name)
      expect(response.body).to include(concept.slug)
      expect(response.body).to include(membership.record.title)
    end
  end

  describe "POST /admin/content_manager/concepts" do
    before { sign_in admin }

    it "successfully creates a concept and enqueues backfill" do
      allow_any_instance_of(Concepts::AnchorGenerator).to receive(:call) do |generator|
        concept_instance = generator.instance_variable_get(:@concept)
        concept_instance.anchor_embedding = embedding
        concept_instance.description = "Synthetic description" if concept_instance.description.blank?
      end

      allow(Concepts::BackfillClassifierWorker).to receive(:perform_async)

      expect {
        post admin_concepts_path, params: { concept: { name: "Claude 3.5 Sonnet", description: "Anthropic's model" } }
      }.to change(Concept, :count).by(1)

      new_concept = Concept.find_by(name: "Claude 3.5 Sonnet")
      expect(response).to redirect_to(admin_concepts_path)
      expect(Concepts::BackfillClassifierWorker).to have_received(:perform_async).with(new_concept.id)
    end
  end

  describe "PUT /admin/content_manager/concepts/:id" do
    before { sign_in admin }

    it "updates details and triggers backfill" do
      allow(Concepts::BackfillClassifierWorker).to receive(:perform_async)
      allow_any_instance_of(Concepts::AnchorGenerator).to receive(:call)

      patch admin_concept_path(concept), params: { concept: { name: "Updated Concept Name" } }
      expect(concept.reload.name).to eq("Updated Concept Name")
      expect(response).to redirect_to(admin_concepts_path)
      expect(Concepts::BackfillClassifierWorker).to have_received(:perform_async).with(concept.id)
    end
  end

  describe "DELETE /admin/content_manager/concepts/:id" do
    before { sign_in admin }

    it "deletes the concept" do
      expect {
        delete admin_concept_path(concept)
      }.to change(Concept, :count).by(-1)

      expect(response).to redirect_to(admin_concepts_path)
    end
  end
end
