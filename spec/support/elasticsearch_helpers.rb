# Only included in specs with elasticsearch: true
module ElasticsearchHelpers
  def index_documents(resources)
    index_documents_for_search_class(Array.wrap(resources), described_class)
  end

  def index_documents_for_search_class(records, search_class)
    records.each(&:index_to_elasticsearch_inline)
    search_class.refresh_index
  end

  def clear_elasticsearch_data(search_class)
    search_class.refresh_index
    Search::Client.delete_by_query(
      index: search_class::INDEX_ALIAS, body: { query: { match_all: {} } },
    )
    search_class.refresh_index
  end
end
