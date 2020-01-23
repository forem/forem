module Reactions
  class BustHomepageCacheWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority, retry: 10

    def perform(reaction_id)
      cache_buster = CacheBuster
      reaction = Reaction.find_by(id: reaction_id, reactable_type: "Article")
      return unless reaction&.reactable

      featured_articles_ids = Article.where(featured: true).order("hotness_score DESC").limit(3).pluck(:id)
      return unless featured_articles_ids.include?(reaction.reactable_id)

      reaction.reactable.touch
      cache_buster.bust("/")
      cache_buster.bust("/")
      cache_buster.bust("/?i=i")
      cache_buster.bust("?i=i")
    end
  end
end
