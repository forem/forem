require "rails_helper"

class SearchableModel
  include Searchable
  SEARCH_CLASS = Search::Tag
  SEARCH_SERIALIZER = Search::TagSerializer

  def id
    1
  end
end

RSpec.describe Searchable do
  let(:model_class) { SearchableModel }
  let(:searchable_model) { model_class.new }
  let(:serialized_hash) { { data: { attributes: { id: searchable_model.search_id } } } }

  before do
    mock_serializer = instance_double("MockSerializer", :serializable_hash)
    allow(model_class::SEARCH_SERIALIZER).to receive(:new).and_return(mock_serializer)
    allow(mock_serializer).to receive(:serializable_hash).and_return(
      serialized_hash,
    )
  end

  describe "#search_id" do
    it "defaults to id" do
      expect(searchable_model.search_id).to equal(searchable_model.id)
    end
  end

  describe "#remove_from_elasticsearch" do
    it "enqueues job to delete model document from elasticsearch" do
      sidekiq_assert_enqueued_with(job: Search::RemoveFromElasticsearchIndexWorker, args: [SearchableModel::SEARCH_CLASS.to_s, searchable_model.search_id]) do
        searchable_model.remove_from_elasticsearch
      end
    end
  end

  describe "#index_to_elasticsearch" do
    it "enqueues job to index document to elasticsearch" do
      sidekiq_assert_enqueued_with(job: Search::IndexToElasticsearchWorker, args: ["SearchableModel", searchable_model.search_id]) do
        searchable_model.index_to_elasticsearch
      end
    end
  end

  describe "#index_to_elasticsearch_inline" do
    it "indexes a document to elasticsearch inline" do
      allow(model_class::SEARCH_CLASS).to receive(:index)
      searchable_model.index_to_elasticsearch_inline
      expect(model_class::SEARCH_CLASS).to have_received(:index).with(searchable_model.search_id, id: searchable_model.search_id)
    end
  end

  describe "#serialized_search_hash" do
    it "creates a valid serialized hash to send to elasticsearch" do
      expect(searchable_model.serialized_search_hash.symbolize_keys.keys).to eq([:id])
    end
  end

  describe "#elasticsearch_doc" do
    it "finds document in elasticsearch" do
      allow(model_class::SEARCH_CLASS).to receive(:find_document)
      searchable_model.elasticsearch_doc
      expect(model_class::SEARCH_CLASS).to have_received(:find_document)
    end
  end
end
