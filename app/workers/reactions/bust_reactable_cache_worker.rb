module Reactions
  class BustReactableCacheWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority, retry: 10

    def perform(reaction_id)
      reaction = Reaction.find_by(id: reaction_id)
      return unless reaction&.reactable

      buster = EdgeCache::Buster.new
      buster.bust(reaction.user.path)

      case reaction.reactable_type
      when "Article"
        buster.bust("/reactions?article_id=#{reaction.reactable_id}")
      when "Comment"
        path = "/reactions?commentable_id=#{reaction.reactable.commentable_id}&" \
          "commentable_type=#{reaction.reactable.commentable_type}"
        buster.bust(path)
      end
    end
  end
end
