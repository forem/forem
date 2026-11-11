require "rails_helper"
require "requests/shared_examples/internal_policy_dependant_request"

RSpec.describe "Admin::ConceptsController" do
  let(:admin) { create(:user, :super_admin) }
  let(:embedding) { Array.new(768, 0.1) }
  let!(:concept) { create(:concept, anchor_embedding: embedding) }

  def collect_sql_queries(&block)
    queries = []
    callback = lambda do |_name, _start, _finish, _id, payload|
      next if payload[:name] == "SCHEMA" || payload[:cached]

      queries << payload[:sql].to_s
    end
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record", &block)
    queries
  end

  it_behaves_like "an InternalPolicy dependant request", Concept do
    let(:request) { get admin_concepts_path }
  end

  describe "GET /admin/content_manager/concepts" do
    before { sign_in admin }

    it "returns a successful response" do
      get admin_concepts_path
      expect(response).to have_http_status(:ok)
    end

    it "wires parent concepts in memory and omits anchor_embedding from concept queries" do
      child_concept = create(:concept, name: "Child Concept", parent: concept, anchor_embedding: embedding)
      create(:concept_membership, concept: child_concept)

      concept_queries = collect_sql_queries { get admin_concepts_path }.grep(/FROM "concepts"/)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Child Concept", concept.name)
      expect(concept_queries.size).to eq(1)
      expect(concept_queries.first).not_to include("anchor_embedding")
    end
  end

  describe "GET /admin/content_manager/concepts/:id" do
    before do
      sign_in admin
      create(:concept_daily_metric, concept: concept)
    end

    let!(:membership) { create(:concept_membership, concept: concept) }

    it "returns a successful response and renders details, chart, and memberships" do
      get admin_concept_path(concept)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(concept.name)
      expect(response.body).to include(concept.slug)
      expect(response.body).to include(membership.record.title)
    end

    it "preloads commentable titles, avoids redundant membership counts, and omits vector embeddings" do
      parent_concept = create(:concept, name: "Parent Concept", anchor_embedding: embedding)
      concept.update!(parent: parent_concept)

      comment_articles = create_list(:article, 3)
      comment_articles.each do |article|
        comment = create(:comment, commentable: article, body_markdown: "Comment on #{article.title}")
        create(:concept_membership, concept: concept, record: comment, distance: 0.12)
      end

      queries = collect_sql_queries { get admin_concept_path(concept) }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Parent Concept", *comment_articles.map(&:title))

      membership_count_queries = queries.select do |sql|
        sql.include?("COUNT(*)") && sql.include?('"concept_memberships"')
      end
      article_queries = queries.grep(/FROM "articles"/)
      author_queries = queries.select { |sql| sql.include?('SELECT "users"."id", "users"."username" FROM "users"') }

      expect(membership_count_queries).to be_empty
      expect(article_queries.size).to eq(1)
      expect(author_queries.size).to eq(1)
      expect(queries.join(" ")).not_to include("anchor_embedding", "semantic_embedding", '"articles".*', '"comments".*')
    end
  end

  describe "GET /admin/content_manager/concepts/:id/edit" do
    before { sign_in admin }

    it "renders the edit form without loading anchor_embedding" do
      create(:concept, name: "Another Concept", anchor_embedding: embedding)

      concept_queries = collect_sql_queries { get edit_admin_concept_path(concept) }.grep(/FROM "concepts"/)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Another Concept")
      expect(concept_queries).not_to be_empty
      expect(concept_queries.join(" ")).not_to include("anchor_embedding")
    end
  end

  describe "POST /admin/content_manager/concepts" do
    before { sign_in admin }

    it "successfully creates a concept and enqueues backfill" do
      generator = instance_double(Concepts::AnchorGenerator)
      allow(Concepts::AnchorGenerator).to receive(:new) do |concept_instance|
        allow(generator).to receive(:call) do
          concept_instance.anchor_embedding = embedding
          concept_instance.description = "Synthetic description" if concept_instance.description.blank?
        end
        generator
      end

      allow(Concepts::BackfillClassifierWorker).to receive(:perform_async)

      expect do
        post admin_concepts_path, params: { concept: { name: "Claude 3.5 Sonnet", description: "Anthropic's model" } }
      end.to change(Concept, :count).by(1)

      new_concept = Concept.find_by(name: "Claude 3.5 Sonnet")
      expect(response).to redirect_to(admin_concepts_path)
      expect(Concepts::BackfillClassifierWorker).to have_received(:perform_async).with(new_concept.id)
    end
  end

  describe "PUT /admin/content_manager/concepts/:id" do
    before { sign_in admin }

    it "updates details and triggers backfill" do
      allow(Concepts::BackfillClassifierWorker).to receive(:perform_async)
      generator = instance_double(Concepts::AnchorGenerator, call: nil)
      allow(Concepts::AnchorGenerator).to receive(:new).and_return(generator)

      patch admin_concept_path(concept), params: { concept: { name: "Updated Concept Name" } }
      expect(concept.reload.name).to eq("Updated Concept Name")
      expect(response).to redirect_to(admin_concepts_path)
      expect(Concepts::BackfillClassifierWorker).to have_received(:perform_async).with(concept.id)
    end
  end

  describe "DELETE /admin/content_manager/concepts/:id" do
    before { sign_in admin }

    it "deletes the concept" do
      expect do
        delete admin_concept_path(concept)
      end.to change(Concept, :count).by(-1)

      expect(response).to redirect_to(admin_concepts_path)
    end
  end

  describe "POST /admin/content_manager/concepts/:id/trigger_lookback" do
    before { sign_in admin }

    context "with valid days" do
      it "enqueues the LookbackWorker and redirects to show" do
        allow(Concepts::LookbackWorker).to receive(:perform_async)

        post trigger_lookback_admin_concept_path(concept), params: { days: 40 }

        expect(response).to redirect_to(admin_concept_path(concept))
        expect(flash[:success]).to be_present
        expect(Concepts::LookbackWorker).to have_received(:perform_async).with(concept.id, 40)
      end
    end

    context "with invalid days" do
      it "does not enqueue the worker and shows error" do
        allow(Concepts::LookbackWorker).to receive(:perform_async)

        post trigger_lookback_admin_concept_path(concept), params: { days: -10 }

        expect(response).to redirect_to(admin_concept_path(concept))
        expect(flash[:error]).to be_present
        expect(Concepts::LookbackWorker).not_to have_received(:perform_async)
      end

      it "does not enqueue when requested days is less than or equal to max_lookback_days" do
        concept.update!(max_lookback_days: 40)
        allow(Concepts::LookbackWorker).to receive(:perform_async)

        post trigger_lookback_admin_concept_path(concept), params: { days: 30 }

        expect(response).to redirect_to(admin_concept_path(concept))
        expect(flash[:error]).to be_present
        expect(Concepts::LookbackWorker).not_to have_received(:perform_async)
      end
    end
  end
end
