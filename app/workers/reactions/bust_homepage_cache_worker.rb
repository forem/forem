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
      buster = EdgeCache::Buster.new
      buster.bust("/")
      buster.bust("/")
      buster.bust("/?i=i")
      buster.bust("?i=i")
    end
  end
end
