module Notifications
  class ModerationNotificationWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority, retry: 10

    def perform(notifiable_id)
      random_moderators = Notifications::Moderation.available_moderators.order(Arel.sql("RANDOM()")).first(2)
      return unless random_moderators.any?

      # notifiable is currently only comment
      notifiable = Comment.find_by(id: notifiable_id)
      return unless notifiable

      random_moderators.each do |mod|
        Notifications::Moderation::Send.call(mod, notifiable)
      end
    end
  end
end
