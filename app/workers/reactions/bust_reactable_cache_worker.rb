module Reactions
  class BustReactableCacheWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority, retry: 10

    def perform(reaction_id)
      reaction = Reaction.find_by(id: reaction_id)
      return unless reaction&.reactable

      CacheBuster.bust reaction.user.path
      if reaction.reactable_type == "Article"
        CacheBuster.bust "/reactions?article_id=#{reaction.reactable_id}"
      elsif reaction.reactable_type == "Comment"
        path = "/reactions?commentable_id=#{reaction.reactable.commentable_id}&commentable_type=#{reaction.reactable.commentable_type}"
        CacheBuster.bust(path)
      end
    end
  end
end
