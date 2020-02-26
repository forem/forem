# Only included in specs with elasticsearch: true
module ElasticsearchHelpers
  def index_documents(resources)
    resources = [resources] unless resources.respond_to?(:each)

    resources.each(&:index_to_elasticsearch_inline)
    described_class.refresh_index
  end
end
