module Search
  class BulkIndexWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority, lock: :until_executing

    def perform(object_class, ids)
      data_hashes = object_class.constantize.
        eager_load_serialized_data.
        where(id: ids).
        find_each.map(&:serialized_search_hash)

      search_class = object_class.constantize::SEARCH_CLASS

      search_class.bulk_index(data_hashes)
    end
  end
end
