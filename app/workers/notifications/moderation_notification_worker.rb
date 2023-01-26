module Notifications
  class ModerationNotificationWorker
    include Sidekiq::Job

    sidekiq_options queue: :medium_priority, retry: 10

    def perform(notifiable_id)
      random_moderators = Notifications::Moderation.available_moderators.order(Arel.sql("RANDOM()")).first(4)
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
