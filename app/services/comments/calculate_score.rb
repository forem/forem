module Comments
  class CalculateScore
    def self.call(...)
      new(...).call
    end

    def initialize(comment)
      @comment = comment
    end

    def call
      score = BlackBox.comment_quality_score(comment)
      score -= 500 if comment.user&.spam?
      score += Settings::UserExperience.index_minimum_score if comment.user&.base_subscriber?
      previous_score = comment.score.to_i
      comment.update_columns(score: score, updated_at: Time.current)

      enqueue_article_activity_update(previous_score, score) if comment.commentable_type == "Article"

      comment.user&.touch(:last_comment_at)

      # update commentable
      commentable = comment.commentable

      commentable.touch(:last_comment_at) if commentable.respond_to?(:last_comment_at)
      Comments::Count.call(commentable, recalculate: true) if commentable.is_a?(Article)

      # busting comment cache includes busting commentable cache
      Comments::BustCacheWorker.new.perform(comment.id)
    end

    private

    attr_reader :comment

    # Emit an article-activity enqueue when the comment crosses the
    # "counted" threshold (score > 0). update_columns above bypasses
    # callbacks, so the Comment after_commit can't observe this transition.
    def enqueue_article_activity_update(previous_score, current_score)
      was_counted = previous_score.positive?
      is_counted = current_score.to_i.positive?
      return if was_counted == is_counted

      action = is_counted ? "create" : "destroy"
      payload = { "iso" => comment.created_at.to_date.iso8601 }
      Articles::UpdateArticleActivityWorker.perform_async(
        comment.commentable_id, "comment", action, payload
      )
    end
  end
end
