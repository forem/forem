module Reactions
  class BustReactableCacheWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority, retry: 10

    def perform(reaction_id)
      reaction = Reaction.find_by(id: reaction_id)
      return unless reaction&.reactable

      EdgeCache::Bust.call(reaction.user.path)
      case reaction.reactable_type
      when "Article"
        EdgeCache::Bust.call("/reactions?article_id=#{reaction.reactable_id}")
      when "Comment"
        path = "/reactions?commentable_id=#{reaction.reactable.commentable_id}&" \
          "commentable_type=#{reaction.reactable.commentable_type}"
        EdgeCache::Bust.call(path)
      end
    end
  end
end
