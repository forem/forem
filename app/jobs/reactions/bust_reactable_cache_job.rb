module Reactions
  class BustReactableCacheJob < ApplicationJob
    queue_as :bust_reactable_cache

    def perform(reaction_id, cache_buster = CacheBuster.new)
      reaction = Reaction.find_by(id: reaction_id)
      return unless reaction&.reactable

      cache_buster.bust reaction.user.path
      if reaction.reactable_type == "Article"
        cache_buster.bust "/reactions?article_id=#{reaction.reactable_id}"
      elsif reaction.reactable_type == "Comment"
        path = "/reactions?commentable_id=#{reaction.reactable.commentable_id}&commentable_type=#{reaction.reactable.commentable_type}"
        cache_buster.bust path
      end
    end
  end
end
