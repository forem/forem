module Notifications
  class RemoveAllByActionWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority, retry: 10

    def perform(notifiable_ids, notifiable_type, action)
      return unless %w[Article Comment Mention].include?(notifiable_type) && notifiable_ids.present?

      Notifications::RemoveAllByAction.call(Array.wrap(notifiable_ids), notifiable_type, action)
    end
  end
end
