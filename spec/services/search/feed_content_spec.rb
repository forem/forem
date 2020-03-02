require "rails_helper"

RSpec.describe Search::FeedContent, type: :service, elasticsearch: true do
  let(:feed_content_id) { 123 }

  describe "::index" do
    it "indexes a feed content to elasticsearch" do
      expect { described_class.find_document(feed_content_id) }.to raise_error(Search::Errors::Transport::NotFound)
      described_class.index(feed_content_id, id: feed_content_id)
      expect(described_class.find_document(feed_content_id)).not_to be_nil
    end
  end

  describe "::find_document" do
    it "fetches a document for a given ID from elasticsearch" do
      described_class.index(feed_content_id, id: feed_content_id)
      expect { described_class.find_document(feed_content_id) }.not_to raise_error
    end
  end

  describe "::delete_document" do
    it "deletes a document for a given ID from elasticsearch" do
      described_class.index(feed_content_id, id: feed_content_id)
      expect { described_class.find_document(feed_content_id) }.not_to raise_error
      described_class.delete_document(feed_content_id)
      expect { described_class.find_document(feed_content_id) }.to raise_error(Search::Errors::Transport::NotFound)
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
    it "updates index mappings for feed content index", :aggregate_failures do
      other_name = "random"
      described_class.create_index(index_name: other_name)
      initial_mapping = Search::Client.indices.get_mapping(index: other_name).dig(other_name, "mappings")
      expect(initial_mapping).to be_empty

      described_class.update_mappings(index_alias: other_name)
      es_mapping_keys = Search::Client.indices.get_mapping(index: other_name).dig(other_name, "mappings", "properties").symbolize_keys.keys
      mapping_keys = described_class::MAPPINGS.dig(:properties).keys

      expect(mapping_keys).to match_array(es_mapping_keys)

      # Cleanup index since it wont automatically be handled by our cluster class bc of the unexpected name
      described_class.delete_index(index_name: other_name)
    end
  end
end
