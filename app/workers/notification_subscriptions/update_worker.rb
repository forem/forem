module NotificationSubscriptions
  class UpdateWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority, retry: 10, lock: :until_executing

    def perform(notifiable_id, notifiable_class)
      raise InvalidNotifiableForUpdate, notifiable_class unless %w[Article].include?(notifiable_class)

      notifiable = notifiable_class.constantize.find_by(id: notifiable_id)

      return unless notifiable

      NotificationSubscriptions::Update.call(notifiable)
    end
  end

  class InvalidNotifiableForUpdate < StandardError; end
end
