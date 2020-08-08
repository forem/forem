module Comments
  class CreateNotificationSubscriptionWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority

    def perform(user_id, comment_id)
      comment = Comment.find(comment_id)
      user = User.find(user_id)
      NotificationSubscription.create(
        user: user, notifiable_id: comment.id, notifiable_type: "Comment", config: "all_comments",
      )
    end
  end
end
