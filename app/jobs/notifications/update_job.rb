module Notifications
  class UpdateJob < ApplicationJob
    queue_as :update_notifications

    def perform(notifiable_id, notifiable_class, action = nil, service = Notifications::Update)
      raise InvalidNotifiableForUpdate, notifiable_class unless %w[Article Comment].include?(notifiable_class)

      notifiable = notifiable_class.constantize.find_by(id: notifiable_id)

      return unless notifiable

      service.call(notifiable, action)
    end
  end

  class InvalidNotifiableForUpdate < StandardError; end
end
