module Reactions
  class BustHomepageCacheWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority, retry: 10

    def perform(reaction_id)
      reaction = Reaction.find_by(id: reaction_id, reactable_type: "Article")
      return unless reaction&.reactable

      featured_articles_ids = Article.where(featured: true).order(hotness_score: :desc).limit(3).ids
      return unless featured_articles_ids.include?(reaction.reactable_id)

      reaction.reactable.touch
      cache_bust = EdgeCache::Bust.new
      cache_bust.call("/")
      cache_bust.call("/")
      cache_bust.call("/?i=i")
      cache_bust.call("?i=i")
    end
  end
end
