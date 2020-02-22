module Search
  class RemoveFromElasticsearchIndexWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority

    def perform(search_class, id)
      search_class.safe_constantize.delete_document(id)
    end
  end
end
