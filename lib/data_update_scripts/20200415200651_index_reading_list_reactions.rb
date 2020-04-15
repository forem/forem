module DataUpdateScripts
  class IndexReadingListReactions
    def run
      Reaction.readinglist.select(:id).in_batches do |batch|
        Search::BulkIndexToElasticsearchWorker.set(queue: :default).perform_async(
          "Reaction", batch.map(&:id)
        )
      end
    end
  end
end
