module Search
  class IndexToElasticsearchWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority

    def perform(search_class, id)
      object = search_class.safe_constantize.find(id)
      object.index_to_elasticsearch_inline
    end
  end
end
