module DataUpdateScripts
  class ReindexReadingListReactions
    def run
      # Reactions are no longer indexed in Elasticsearch
      # Reaction.readinglist.select(:id).in_batches do |batch|
      #   Search::BulkIndexWorker.set(queue: :default).perform_async(
      #     "Reaction", batch.ids
      #   )
      # end
    end
  end
end
