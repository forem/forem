# Only included in specs with elasticsearch: true
module ElasticsearchHelpers
  def index_documents(resources)
    Array.wrap(resources).each do |resource|
      resource.index_to_elasticsearch_inline
      resource::SEARCH_CLASS.refresh_index
    end
  end
end
