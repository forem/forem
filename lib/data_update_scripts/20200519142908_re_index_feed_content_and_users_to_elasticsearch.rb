module DataUpdateScripts
  class ReIndexFeedContentAndUsersToElasticsearch
    def run
      Article.select(:id).in_batches(of: 100) do |batch|
        Search::BulkIndexWorker.set(queue: :default).perform_async(
          "Article", batch.pluck(:id)
        )
      end
      Comment.select(:id).in_batches(of: 100) do |batch|
        Search::BulkIndexWorker.set(queue: :default).perform_async(
          "Comment", batch.pluck(:id)
        )
      end
      PodcastEpisode.select(:id).in_batches(of: 100) do |batch|
        Search::BulkIndexWorker.set(queue: :default).perform_async(
          "PodcastEpisode", batch.pluck(:id)
        )
      end

      User.select(:id).in_batches(of: 200) do |batch|
        Search::BulkIndexWorker.set(queue: :default).perform_async(
          "User", batch.pluck(:id)
        )
      end
    end
  end
end
