module Search
  class ReindexRelatedDocuments
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority

    def perform(object_class, object_id, relation)
      object = object_class.constantize.find(object_id)
      object.send(relation).find_each(&:index_to_elasticsearch_inline)
    end
  end
end
