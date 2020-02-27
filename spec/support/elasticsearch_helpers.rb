# Only included in specs with elasticsearch: true
module ElasticsearchHelpers
  def index_documents(resources)
    Array.wrap(resources).each(&:index_to_elasticsearch_inline)
    described_class.refresh_index
  end
end
