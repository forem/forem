module Reactions
  class BustHomepageCacheWorker
    include Sidekiq::Job

    sidekiq_options queue: :high_priority, retry: 10

    def perform(reaction_id)
      reaction = Reaction.find_by(id: reaction_id, reactable_type: "Article")
      return unless reaction

      # Check the (cheap) featured ids before hydrating the full article row, so
      # reactions on non-featured articles never load articles.*. Scoping to
      # published articles lets PostgreSQL satisfy the top-3 lookup via the
      # partial index index_articles_on_hotness_score_for_featured_published
      # instead of scanning the full-table hotness_score index backwards.
      featured_articles_ids = Article.published.featured.order(hotness_score: :desc).limit(3).ids
      return unless featured_articles_ids.include?(reaction.reactable_id)
      return unless reaction.reactable

      reaction.reactable.touch
      EdgeCache::PurgeByKey.call("main_app_home_page", fallback_paths: "/")
    end
  end
end
