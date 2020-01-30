module Notifications
  class UpdateWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority, retry: 10

    def perform(notifiable_id, notifiable_class, action = nil)
      raise InvalidNotifiableForUpdate, notifiable_class unless %w[Article Comment].include?(notifiable_class)

      notifiable = notifiable_class.constantize.find_by(id: notifiable_id)

      return unless notifiable

      Notifications::Update.call(notifiable, action)
    end
  end

  class InvalidNotifiableForUpdate < StandardError; end
end
