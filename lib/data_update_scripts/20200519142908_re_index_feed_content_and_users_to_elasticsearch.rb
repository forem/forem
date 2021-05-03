module DataUpdateScripts
  class ReIndexFeedContentAndUsersToElasticsearch
    def run
      # Article.select(:id).in_batches(of: 100) do |batch|
      #   Search::BulkIndexWorker.set(queue: :default).perform_async(
      #     "Article", batch.ids
      #   )
      # end
      # Comment.select(:id).in_batches(of: 100) do |batch|
      #   Search::BulkIndexWorker.set(queue: :default).perform_async(
      #     "Comment", batch.ids
      #   )
      # end
      # PodcastEpisode.select(:id).in_batches(of: 100) do |batch|
      #   Search::BulkIndexWorker.set(queue: :default).perform_async(
      #     "PodcastEpisode", batch.ids
      #   )
      # end

      # See: https://github.com/forem/forem/pull/10313#discussion_r487646864
      # User.select(:id).in_batches(of: 200) do |batch|
      #  Search::BulkIndexWorker.set(queue: :default).perform_async(
      #    "User", batch.ids
      #  )
      # end
    end
  end
end
