module Search
  class IndexWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority, lock: :until_executing

    def perform(object_class, id)
      object = object_class.constantize.find_by(id: id)
      object&.index_to_elasticsearch_inline
    end
  end
end
