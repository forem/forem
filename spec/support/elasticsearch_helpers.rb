# Only included in specs with elasticsearch: true
module ElasticsearchHelpers
  def index_documents(resources)
    Array.wrap(resources).each(&:index_to_elasticsearch_inline)
    described_class.refresh_index
  end

  def clear_elasticsearch_data(search_class)
    Search::Client.delete_by_query(
      index: search_class::INDEX_ALIAS, body: { query: { match_all: {} } },
    )
    search_class.refresh_index
  end
end
