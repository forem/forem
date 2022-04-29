module Comments
  class CreateFirstReactionWorker
    include Sidekiq::Job

    sidekiq_options queue: :high_priority, retry: 10

    def perform(comment_id, user_id)
      return unless Comment.exists?(id: comment_id)

      Reaction.create(
        user_id: user_id,
        reactable_id: comment_id,
        reactable_type: "Comment",
        category: "like",
      )
    end
  end
end
