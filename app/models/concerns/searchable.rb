module Searchable
  def search_id
    id
  end

  def index_to_elasticsearch
    Search::IndexToElasticsearchWorker.perform_async(self.class.name, id)
  end

  def index_to_elasticsearch_inline
    self.class::SEARCH_CLASS.index(search_id, serialized_search_hash)
  end

  def remove_from_elasticsearch
    Search::RemoveFromElasticsearchIndexWorker.perform_async(self.class::SEARCH_CLASS.to_s, search_id)
  end

  def serialized_search_hash
    self.class::SEARCH_SERIALIZER.new(self).serializable_hash.dig(:data, :attributes)
  end

  def elasticsearch_doc
    self.class::SEARCH_CLASS.find_document(search_id)
  end

  def sync_related_elasticsearch_docs
    self.class::DATA_SYNC_CLASS.new(self).call
  end

  def elasticsearch_doc_exists?
    self.class::SEARCH_CLASS.document_exists?(search_id)
  end
end
