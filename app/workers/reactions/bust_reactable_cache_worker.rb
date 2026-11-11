module Reactions
  class BustReactableCacheWorker
    include Sidekiq::Job

    sidekiq_options queue: :high_priority, retry: 10

    def perform(reaction_id)
      reaction = Reaction.find_by(id: reaction_id)
      return unless reaction

      case reaction.reactable_type
      when "Article"
        bust_article_reaction_cache(reaction)
      when "Comment"
        bust_comment_reaction_cache(reaction)
      else
        return unless reaction.reactable

        purge_reactor_profile_cache(reaction)
      end
    end

    private

    def bust_article_reaction_cache(reaction)
      article_id = reaction.reactable_id
      return unless Article.exists?(id: article_id)

      purge_reactor_profile_cache(reaction)
      EdgeCache::PurgeByKey.call(
        Reaction.surrogate_key_for_article(article_id),
        fallback_paths: "/reactions?article_id=#{article_id}",
      )

      # We only want to bust on the creation or deletion of the "first" reaction.
      # This is logically called *after* creation, but *before* deletion. So "1" is correct in each case.
      # Avoid hydrating the full Article row (body, HTML, embeddings) when >1 reactions exist.
      if Reaction.for_articles([article_id]).public_category.size == 1 && (article = reaction.reactable)
        EdgeCache::BustArticle.call(article)
      end
      Articles::UpdateDependentEmbedsWorker.perform_async(article_id)
    end

    def bust_comment_reaction_cache(reaction)
      comment = Comment.select(:id, :commentable_id, :commentable_type).find_by(id: reaction.reactable_id)
      return unless comment

      purge_reactor_profile_cache(reaction)
      return unless comment.commentable_id && comment.commentable_type.in?(Comment::COMMENTABLE_TYPES)

      commentable = comment.commentable_type.constantize.select(:id).find_by(id: comment.commentable_id)
      return unless commentable

      EdgeCache::PurgeByKey.call(
        Reaction.surrogate_key_for_commentable(commentable),
        fallback_paths: "/reactions?commentable_id=#{commentable.id}&commentable_type=#{commentable.class.name}",
      )
    end

    def purge_reactor_profile_cache(reaction)
      user = User.select(:id, :username).find_by(id: reaction.user_id) if reaction.user_id
      EdgeCache::PurgeByKey.call(
        user&.profile_identity_record_key,
        fallback_paths: user ? [user.path] : nil,
      )
    end
  end
end
