require "rails_helper"

RSpec.describe Search::Tag, type: :service, elasticsearch: true do
  describe "::search_documents" do
    let(:tag_doc_1) { { "name" => "tag1" } }
    let(:tag_doc_2) { { "name" => "tag2" } }
    let(:mock_search_response) do
      {
        "hits" => {
          "hits" => [
            { "_source" => tag_doc_1 },
            { "_source" => tag_doc_2 },
          ]
        }
      }
    end

    it "searches with name:tag" do
      tag = create(:tag, :search_indexed, name: "tag1")

      described_class.refresh_index
      tag_docs = described_class.search_documents("name:#{tag.name}")
      expect(tag_docs.count).to eq(1)
      expect(tag_docs).to match([
                                  a_hash_including("name" => tag.name),
                                ])
    end

    it "analyzes wildcards" do
      tag1 = create(:tag, :search_indexed, name: "tag1")
      tag2 = create(:tag, :search_indexed, name: "tag2")
      tag3 = create(:tag, :search_indexed, name: "3tag")

      described_class.refresh_index

      tag_docs = described_class.search_documents("name:tag*")
      expect(tag_docs).to match([
                                  a_hash_including("name" => tag1.name),
                                  a_hash_including("name" => tag2.name),
                                ])
      expect(tag_docs).not_to match(a_hash_including("name" => tag3.name))
    end

    it "parses tag document hits from search response" do
      allow(Search::Client).to receive(:search) { mock_search_response }
      tag_docs = described_class.search_documents("query")
      expect(tag_docs.count).to eq(2)
      expect(tag_docs).to include(tag_doc_1, tag_doc_2)
    end

    it "does not allow leading wildcards" do
      expect { described_class.search_documents("name:*tag") }.to raise_error(Search::Errors::Transport::BadRequest)
    end
  end
end
