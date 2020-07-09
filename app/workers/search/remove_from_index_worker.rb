module Search
  class RemoveFromIndexWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority, lock: :until_executing

    def perform(search_class, id)
      search_class.safe_constantize.delete_document(id)
    rescue Search::Errors::Transport::NotFound
      # Often race conditions cause us never to index a document and
      # we end up with an error when trying to remove it. Because
      # we have count checks that run every hour to track the counts in
      # Elasticsearch and db to ensure they match we can ignore this error
      nil
    end
  end
end
