require "rails_helper"

RSpec.describe Search::FeedContent, type: :service do
  it "defines INDEX_NAME, INDEX_ALIAS, and MAPPINGS", :aggregate_failures do
    expect(described_class::INDEX_NAME).not_to be_nil
    expect(described_class::INDEX_ALIAS).not_to be_nil
    expect(described_class::MAPPINGS).not_to be_nil
  end

  describe "::search_documents", elasticsearch: true do
    let(:article1) { create(:article) }
    let(:article2) { create(:article) }

    it "parses feed content document hits from search response" do
      mock_search_response = { "hits" => { "hits" => {} } }
      allow(described_class).to receive(:search) { mock_search_response }
      described_class.search_documents(params: {})
      expect(described_class).to have_received(:search).with(body: a_kind_of(Hash))
    end

    context "with a query" do
      it "searches by search_fields" do
        allow(article1).to receive(:title).and_return("ruby")
        allow(article2).to receive(:body_text).and_return("Ruby Tuesday")
        index_documents([article1, article2])
        query_params = { size: 5, search_fields: "ruby" }

        article_docs = described_class.search_documents(params: query_params)
        expect(article_docs.count).to eq(2)
        doc_ids = article_docs.map { |t| t.dig("id") }
        expect(doc_ids).to include(article1.id, article2.id)
      end
    end

    context "with a filter term" do
      it "filters by tag names" do
        article1.tags << create(:tag, name: "ruby")
        article2.tags << create(:tag, name: "python")
        index_documents([article1, article2])
        query_params = { size: 5, tag_names: "ruby" }

        article_docs = described_class.search_documents(params: query_params)
        expect(article_docs.count).to eq(1)
        doc_ids = article_docs.map { |t| t.dig("id") }
        expect(doc_ids).to include(article1.id)
      end

      it "filters by user_id" do
        index_documents([article1, article2])
        query_params = { size: 5, user_id: article1.user_id }

        article_docs = described_class.search_documents(params: query_params)
        expect(article_docs.count).to eq(1)
        doc_ids = article_docs.map { |t| t.dig("id") }
        expect(doc_ids).to include(article1.id)
      end

      it "filters by approved" do
        article1.update(approved: false)
        article2.update(approved: true)
        index_documents([article1, article2])
        query_params = { size: 5, approved: true }

        article_docs = described_class.search_documents(params: query_params)
        expect(article_docs.count).to eq(1)
        doc_ids = article_docs.map { |t| t.dig("id") }
        expect(doc_ids).to include(article2.id)
      end
    end

    context "with range keys" do
      it "searches by published_at" do
        article1.update(published_at: 1.year.ago)
        article2.update(published_at: 1.month.ago)
        index_documents([article1, article2])
        query_params = { size: 5, published_at: { gte: 2.months.ago.iso8601 } }

        article_docs = described_class.search_documents(params: query_params)
        expect(article_docs.count).to eq(1)
        doc_ids = article_docs.map { |t| t.dig("id") }
        expect(doc_ids).to include(article2.id)
      end
    end
  end
end
