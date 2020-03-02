require "rails_helper"

RSpec.describe Search::Tag, type: :service, elasticsearch: true do
  describe "::index" do
    it "indexes a tag to elasticsearch" do
      tag = create(:tag)

      expect { described_class.find_document(tag.id) }.to raise_error(Search::Errors::Transport::NotFound)

      described_class.index(tag.id, tag.serialized_search_hash)
      expect(described_class.find_document(tag.id)).not_to be_nil
    end
  end

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

  describe "::find_document" do
    it "fetches a document for a given ID from elasticsearch" do
      tag = create(:tag)
      described_class.index(tag.id, tag.serialized_search_hash)
      expect { described_class.find_document(tag.id) }.not_to raise_error
    end
  end

  describe "::delete_document" do
    it "deletes a document for a given ID from elasticsearch" do
      tag = create(:tag)
      index_documents(tag)
      expect { described_class.find_document(tag.id) }.not_to raise_error
      described_class.delete_document(tag.id)
      expect { described_class.find_document(tag.id) }.to raise_error(Search::Errors::Transport::NotFound)
    end
  end

  describe "::create_index" do
    it "creates an elasticsearch index with INDEX_NAME" do
      described_class.delete_index
      expect(Search::Client.indices.exists(index: described_class::INDEX_NAME)).to eq(false)
      described_class.create_index
      expect(Search::Client.indices.exists(index: described_class::INDEX_NAME)).to eq(true)
    end

    it "creates an elasticsearch index with name argument" do
      other_name = "random"
      expect(Search::Client.indices.exists(index: other_name)).to eq(false)
      described_class.create_index(index_name: other_name)
      expect(Search::Client.indices.exists(index: other_name)).to eq(true)

      # Have to cleanup index since it wont automatically be handled by our cluster class bc of the unexpected name
      described_class.delete_index(index_name: other_name)
    end
  end

  describe "::delete_index" do
    it "deletes an elasticsearch index with INDEX_NAME" do
      expect(Search::Client.indices.exists(index: described_class::INDEX_NAME)).to eq(true)
      described_class.delete_index
      expect(Search::Client.indices.exists(index: described_class::INDEX_NAME)).to eq(false)
    end

    it "deletes an elasticsearch index with name argument" do
      other_name = "random"
      described_class.create_index(index_name: other_name)
      expect(Search::Client.indices.exists(index: other_name)).to eq(true)

      described_class.delete_index(index_name: other_name)
      expect(Search::Client.indices.exists(index: other_name)).to eq(false)
    end
  end

  describe "::add_alias" do
    it "adds alias INDEX_ALIAS to elasticsearch index with INDEX_NAME" do
      Search::Client.indices.delete_alias(index: described_class::INDEX_NAME, name: described_class::INDEX_ALIAS)
      expect(Search::Client.indices.exists(index: described_class::INDEX_ALIAS)).to eq(false)
      described_class.add_alias
      expect(Search::Client.indices.exists(index: described_class::INDEX_ALIAS)).to eq(true)
    end

    it "adds custom alias to elasticsearch index with INDEX_NAME" do
      other_alias = "random"
      expect(Search::Client.indices.exists(index: other_alias)).to eq(false)
      described_class.add_alias(index_name: described_class::INDEX_NAME, index_alias: other_alias)
      expect(Search::Client.indices.exists(index: other_alias)).to eq(true)
    end
  end

  describe "::update_mappings" do
    it "updates index mappings for tag index", :aggregate_failures do
      other_name = "random"
      described_class.create_index(index_name: other_name)
      initial_mapping = Search::Client.indices.get_mapping(index: other_name).dig(other_name, "mappings")
      expect(initial_mapping).to be_empty

      described_class.update_mappings(index_alias: other_name)
      mapping = Search::Client.indices.get_mapping(index: other_name).dig(other_name, "mappings")
      expect(mapping.deep_stringify_keys).to include(described_class::MAPPINGS.deep_stringify_keys)

      # Have to cleanup index since it wont automatically be handled by our cluster class bc of the unexpected name
      described_class.delete_index(index_name: other_name)
    end
  end
end
