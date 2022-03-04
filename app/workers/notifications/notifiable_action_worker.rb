module Notifications
  class NotifiableActionWorker
    include Sidekiq::Worker

    sidekiq_options queue: :low_priority, retry: 10
    def perform(notifiable_id, notifiable_type, action)
      # checking type, but leaving space for notifiable types
      return unless notifiable_type == "Article"

      notifiable = notifiable_type.constantize.find_by(id: notifiable_id)
      Notifications::NotifiableAction::Send.call(notifiable, action) if notifiable
    end
  end
end
