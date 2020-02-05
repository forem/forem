require "rails_helper"

RSpec.describe Search::Tag, type: :service, elasticsearch: true do
  describe "::index" do
    it "indexes a tag to elasticsearch" do
      tag = FactoryBot.create(:tag)
      expect { described_class.get(tag.id) }.to raise_error(Elasticsearch::Transport::Transport::Errors::NotFound)
      described_class.index(tag.id, tag.serialized_search_hash)
      expect(described_class.get(tag.id)).not_to be_nil
    end
  end

  describe "::get" do
    it "fetches a document for a given ID from elasticsearch" do
      tag = FactoryBot.create(:tag)
      described_class.index(tag.id, tag.serialized_search_hash)
      expect { described_class.get(tag.id) }.not_to raise_error
    end
  end

  describe "::create_index" do
    it "creates an elasticsearch index with INDEX_NAME" do
      described_class.delete_index
      expect(SearchClient.indices.exists(index: described_class::INDEX_NAME)).to eq(false)
      described_class.create_index
      expect(SearchClient.indices.exists(index: described_class::INDEX_NAME)).to eq(true)
    end

    it "creates an elasticsearch index with name argument" do
      other_name = "random"
      expect(SearchClient.indices.exists(index: other_name)).to eq(false)
      described_class.create_index(index_name: other_name)
      expect(SearchClient.indices.exists(index: other_name)).to eq(true)

      # Have to cleanup index since it wont automatically be handled by our cluster class bc of the unexpected name
      described_class.delete_index(index_name: other_name)
    end
  end

  describe "::delete_index" do
    it "deletes an elasticsearch index with INDEX_NAME" do
      expect(SearchClient.indices.exists(index: described_class::INDEX_NAME)).to eq(true)
      described_class.delete_index
      expect(SearchClient.indices.exists(index: described_class::INDEX_NAME)).to eq(false)
    end

    it "deletes an elasticsearch index with name argument" do
      other_name = "random"
      described_class.create_index(index_name: other_name)
      expect(SearchClient.indices.exists(index: other_name)).to eq(true)

      described_class.delete_index(index_name: other_name)
      expect(SearchClient.indices.exists(index: other_name)).to eq(false)
    end
  end

  describe "::add_alias" do
    it "adds alias INDEX_ALIAS to elasticsearch index with INDEX_NAME" do
      SearchClient.indices.delete_alias(index: described_class::INDEX_NAME, name: described_class::INDEX_ALIAS)
      expect(SearchClient.indices.exists(index: described_class::INDEX_ALIAS)).to eq(false)
      described_class.add_alias
      expect(SearchClient.indices.exists(index: described_class::INDEX_ALIAS)).to eq(true)
    end

    it "adds custom alias to elasticsearch index with INDEX_NAME" do
      other_alias = "random"
      expect(SearchClient.indices.exists(index: other_alias)).to eq(false)
      described_class.add_alias(index_name: described_class::INDEX_NAME, index_alias: other_alias)
      expect(SearchClient.indices.exists(index: other_alias)).to eq(true)
    end
  end

  describe "::update_mappings" do
    it "updates index mappings for tag index", :aggregate_failures do
      other_name = "random"
      described_class.create_index(index_name: other_name)
      initial_mapping = SearchClient.indices.get_mapping(index: other_name).dig(other_name, "mappings")
      expect(initial_mapping).to be_empty

      described_class.update_mappings(index_alias: other_name)
      mapping = SearchClient.indices.get_mapping(index: other_name).dig(other_name, "mappings")
      expect(mapping.deep_stringify_keys).to include(described_class.send("mappings").deep_stringify_keys)

      # Have to cleanup index since it wont automatically be handled by our cluster class bc of the unexpected name
      described_class.delete_index(index_name: other_name)
    end
  end
end
