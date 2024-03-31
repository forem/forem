module Notifications
  class CreateRoundRobinModerationNotificationsWorker
    include Sidekiq::Job

    sidekiq_options queue: :medium_priority, retry: 10

    MODERATOR_SAMPLE_SIZE = 4

    def perform(notifiable_id, notifiable_type)
      random_moderators = Users::SelectModeratorsQuery.call.order(Arel.sql("RANDOM()"))
        .first(MODERATOR_SAMPLE_SIZE)
      return unless random_moderators.any?

      if notifiable_type == "Comment"
        notifiable = Comment.find_by(id: notifiable_id)
        # return if it's a comment whose commentable has been deleted
        return unless notifiable&.commentable

      elsif notifiable_type == "Article"
        notifiable = Article.find_by(id: notifiable_id)
      end

      return unless notifiable && !notifiable.user.limited?

      random_moderators.each do |mod|
        next if mod == notifiable.user

        Notifications::Moderation::Send.call(mod, notifiable)
      end
    end
  end
end
