module Notifications
  class CreateRoundRobinModerationNotificationsWorker
    include Sidekiq::Job

    sidekiq_options queue: :medium_priority, retry: 10

    MODERATOR_SAMPLE_SIZE = 4

    def perform(notifiable_id)
      random_moderators = Users::SelectModeratorsQuery.call.order(Arel.sql("RANDOM()"))
        .first(MODERATOR_SAMPLE_SIZE)
      return unless random_moderators.any?

      # notifiable is currently only comment
      notifiable = Comment.find_by(id: notifiable_id)
      return unless notifiable

      # return if it's a comment whose commentable has been deleted
      return unless notifiable.commentable

      random_moderators.each do |mod|
        next if mod == notifiable.user

        Notifications::Moderation::Send.call(mod, notifiable)
      end
    end
  end
end
