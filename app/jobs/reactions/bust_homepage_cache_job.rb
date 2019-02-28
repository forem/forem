module Reactions
  class BustHomepageCacheJob < ApplicationJob
    queue_as :bust_homepage_cache_from_reactions

    def perform(reaction_id, cache_buster = CacheBuster.new)
      reaction = Reaction.find_by(id: reaction_id, reactable_type: "Article")
      return unless reaction&.reactable

      featured_articles_ids = Article.where(featured: true).order("hotness_score DESC").limit(3).pluck(:id)
      return unless featured_articles_ids.include?(reaction.reactable_id)

      reaction.reactable.touch
      cache_buster.bust "/"
      cache_buster.bust "/"
      cache_buster.bust "/?i=i"
      cache_buster.bust "?i=i"
    end
  end
end
