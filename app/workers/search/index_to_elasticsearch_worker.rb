module Search
  class IndexToElasticsearchWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority, lock: :until_executing

    def perform(object_class, id)
      object = object_class.constantize.find(id)
      object.index_to_elasticsearch_inline
    rescue ActiveRecord::RecordNotFound => e
      return if object_class == "Reaction"

      raise e
    end
  end
end
