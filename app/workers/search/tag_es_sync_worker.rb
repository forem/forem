module Search
  class TagEsSyncWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority

    def perform(tag_id)
      tag = ::Tag.find_by(id: tag_id)

      if tag
        tag.index_to_elasticsearch_inline
      else
        Search::Tag.delete_document(tag_id)
      end
    end
  end
end
