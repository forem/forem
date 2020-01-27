module Notifications
  class RemoveAllByActionWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority, retry: 10

    def perform(notifiable_ids, notifiable_type, action)
      notifiable_collection = notifiable_type.constantize.where(id: notifiable_ids)
      return unless %w[Article Comment Mention].include?(notifiable_type) && notifiable_collection.exists?

      Notifications::RemoveAllByAction.call(Array.wrap(notifiable_ids), notifiable_type, action)
    end
  end
end
