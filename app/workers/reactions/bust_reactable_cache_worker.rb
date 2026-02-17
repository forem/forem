module Reactions
  class BustReactableCacheWorker
    include Sidekiq::Job

    sidekiq_options queue: :high_priority, retry: 10

    def perform(reaction_id)
      reaction = Reaction.find_by(id: reaction_id)
      return unless reaction&.reactable

      EdgeCache::PurgeByKey.call(
        reaction.user&.profile_identity_record_key,
        fallback_paths: reaction.user ? [reaction.user.path] : nil,
      )

      case reaction.reactable_type
      when "Article"
        article = reaction.reactable
        EdgeCache::PurgeByKey.call(
          Reaction.surrogate_key_for_article(article.id),
          fallback_paths: "/reactions?article_id=#{article.id}",
        )

        # We only want to bust on the creation or deletion of the "first" reaction.
        # This is logically called *after* creation, but *before* deletion. So "1" is correct in each case.
        if Reaction.for_articles([reaction.reactable_id]).public_category.size == 1
          EdgeCache::BustArticle.call(article)
        end
      when "Comment"
        commentable = reaction.reactable.commentable
        if commentable
          EdgeCache::PurgeByKey.call(
            Reaction.surrogate_key_for_commentable(commentable),
            fallback_paths: "/reactions?commentable_id=#{commentable.id}&commentable_type=#{commentable.class.name}",
          )
        end

      end
    end
  end
end
