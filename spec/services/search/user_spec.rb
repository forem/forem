require "rails_helper"

RSpec.describe Search::User, type: :service do
  it "defines INDEX_NAME, INDEX_ALIAS, and MAPPINGS", :aggregate_failures do
    expect(described_class::INDEX_NAME).not_to be_nil
    expect(described_class::INDEX_ALIAS).not_to be_nil
    expect(described_class::MAPPINGS).not_to be_nil
  end

  describe "::search_documents", elasticsearch: true do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    it "parses user document hits from search response" do
      mock_search_response = { "hits" => { "hits" => {} } }
      allow(described_class).to receive(:search) { mock_search_response }
      described_class.search_documents(params: {})
      expect(described_class).to have_received(:search).with(body: a_kind_of(Hash))
    end

    context "with a query" do
      it "searches by search_fields" do
        allow(user1).to receive(:available_for).and_return("ruby")
        allow(user2).to receive(:employer_name).and_return("Ruby Tuesday")
        index_documents([user1, user2])
        query_params = { size: 5, search_fields: "ruby" }

        user_docs = described_class.search_documents(params: query_params)
        expect(user_docs.count).to eq(2)
        doc_ids = user_docs.map { |t| t.dig("id") }
        expect(doc_ids).to include(user1.id, user2.id)
      end
    end
  end
end
