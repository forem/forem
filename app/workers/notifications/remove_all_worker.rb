module Notifications
  class RemoveAllWorker
    include Sidekiq::Worker

    sidekiq_options queue: :low_priority, retry: 10

    def perform(notifiable_ids, notifiable_type)
      return unless %w[Article Comment Mention].include?(notifiable_type) && notifiable_ids.present?

      Notifications::RemoveAll.call(Array.wrap(notifiable_ids), notifiable_type)
    end
  end
end
