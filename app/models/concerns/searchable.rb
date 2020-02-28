module Searchable
  def index_to_elasticsearch
    Search::IndexToElasticsearchWorker.perform_async(self.class.name, id)
  end

  def index_to_elasticsearch_inline
    self.class::SEARCH_CLASS.index(id, serialized_search_hash)
  end

  def remove_from_elasticsearch
    Search::RemoveFromElasticsearchIndexWorker.perform_async(self.class::SEARCH_CLASS.to_s, id)
  end

  def serialized_search_hash
    self.class::SEARCH_SERIALIZER.new(self).serializable_hash.dig(:data, :attributes)
  end

  def elasticsearch_doc
    self.class::SEARCH_CLASS.find_document(id)
  end
end
