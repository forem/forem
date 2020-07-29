module DataUpdateScripts
  class ReIndexFeedContentAndUsersToElasticsearch
    def run
      Article.select(:id).in_batches(of: 100) do |batch|
        Search::BulkIndexWorker.set(queue: :default).perform_async(
          "Article", batch.ids
        )
      end
      Comment.select(:id).in_batches(of: 100) do |batch|
        Search::BulkIndexWorker.set(queue: :default).perform_async(
          "Comment", batch.ids
        )
      end
      PodcastEpisode.select(:id).in_batches(of: 100) do |batch|
        Search::BulkIndexWorker.set(queue: :default).perform_async(
          "PodcastEpisode", batch.ids
        )
      end

      User.select(:id).in_batches(of: 200) do |batch|
        Search::BulkIndexWorker.set(queue: :default).perform_async(
          "User", batch.ids
        )
      end
    end
  end
end
