module Search
  class TagEsIndexWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority

    def perform(tag_id)
      tag = ::Tag.find_by!(id: tag_id)
      tag.index_to_elasticsearch_inline
    end
  end
end
