module Search
  class IndexToElasticsearchWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority

    def perform(object_class, id)
      object = object_class.constantize.find(id)
      object.index_to_elasticsearch_inline
    end
  end
end
