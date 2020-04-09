require "rails_helper"

RSpec.describe Search::User, type: :service do
  it "defines INDEX_NAME, INDEX_ALIAS, MAPPINGS and SERIALIZER_CLASS", :aggregate_failures do
    expect(described_class::INDEX_NAME).not_to be_nil
    expect(described_class::INDEX_ALIAS).not_to be_nil
    expect(described_class::MAPPINGS).not_to be_nil
    expect(described_class::SERIALIZER_CLASS).not_to be_nil
  end

  describe "::search_documents", elasticsearch: true do
    let(:attributes) { described_class::SERIALIZER_CLASS.attributes_to_serialize.stringify_keys.keys }
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    it "parses user document hits from search response" do
      mock_search_response = { "hits" => { "hits" => {} } }
      allow(described_class).to receive(:search) { mock_search_response }
      described_class.search_documents(params: {})

      expect(described_class).to have_received(:search).with(body: a_kind_of(Hash))
    end

    it "returns user default attributes" do
      index_documents([user1])
      users = described_class.search_documents(params: {}).dig(:users)

      expect(users.first).to include(*attributes)
    end

    context "when paginating results" do
      let(:mock_search_response) do
        {
          "hits" => {
            "total" => {
              "value" => 100
            },
            "hits" => Array.new(100, "_source" => {})
          }
        }
      end

      let(:expected_metadata) do
        {
          total_count: 100,
          total_pages: 10,
          current_page: 2,
          limit_value: 10,
          offset_value: 10,
          size: 20
        }
      end

      before do
        allow(described_class).to receive(:search) { mock_search_response }
      end

      it "returns the correct metadata" do
        doc = described_class.search_documents(params: { page: 2, per_page: 10 })
        expect(doc).to include(expected_metadata)
      end
    end

    context "when query by search_fields" do
      before do
        allow(user1).to receive(:available_for).and_return("ruby")
        allow(user2).to receive(:employer_name).and_return("Ruby Tuesday")
        index_documents([user1, user2])
      end

      let(:query_params) { { size: 5, search_fields: "ruby" } }

      it "returns the correct users" do
        user_docs = described_class.search_documents(params: query_params)
        expect(user_docs.dig("users").size).to eq(2)
        doc_ids = user_docs.dig("users").map { |t| t.dig("id") }
        expect(doc_ids).to include(user1.id, user2.id)
      end
    end

    context "with a filter" do
      before do
        user1.add_role(:admin)
        user2.add_role(:banned)
        index_documents([user1, user2])
      end

      let(:query_params) { { size: 5, exclude_roles: ["banned"] } }

      it "searches by excluding roles" do
        user_docs = described_class.search_documents(params: query_params)
        expect(user_docs.dig("users").size).to eq(1)
        doc_ids = user_docs.dig("users").map { |t| t.dig("id") }
        expect(doc_ids).to match_array([user1.id])
      end
    end
  end
end
