module Reactions
  class BustHomepageCacheWorker
    include Sidekiq::Job

    sidekiq_options queue: :high_priority, retry: 10

    def perform(reaction_id)
      reaction = Reaction.find_by(id: reaction_id, reactable_type: "Article")
      return unless reaction

      # Check the (cheap) featured ids before hydrating the full article row, so
      # reactions on non-featured articles never load articles.*.
      featured_articles_ids = Article.featured.order(hotness_score: :desc).limit(3).ids
      return unless featured_articles_ids.include?(reaction.reactable_id)
      return unless reaction.reactable

      reaction.reactable.touch
      cache_bust = EdgeCache::Bust.new
      cache_bust.call("/")
      cache_bust.call("/")
      cache_bust.call("/?i=i")
      cache_bust.call("?i=i")
    end
  end
end
