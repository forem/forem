module DataUpdateScripts
  class ReindexReadingListReactions
    def run
      Reaction.readinglist.select(:id).in_batches do |batch|
        Search::BulkIndexWorker.set(queue: :default).perform_async(
          "Reaction", batch.ids
        )
      end
    end
  end
end
