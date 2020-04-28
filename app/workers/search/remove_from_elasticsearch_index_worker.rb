module Search
  class RemoveFromElasticsearchIndexWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority, lock: :until_executing

    def perform(search_class, id)
      search_class.safe_constantize.delete_document(id)
    rescue Search::Errors::Transport::NotFound => e
      # Reactions are often destroyed before the indexing job can execute
      # so we ignore this error when trying to remove them
      return if search_class == "Search::Reaction"

      raise e
    end
  end
end
