module Notifications
  class RemoveAllWorker
    include Sidekiq::Worker

    sidekiq_options queue: :low_priority, retry: 10

    def perform(notifiable_ids, notifiable_type, service = Notifications::RemoveAll)
      return unless %w[Article Comment Mention].include?(notifiable_type) && notifiable_ids.present?

      service.call(Array.wrap(notifiable_ids), notifiable_type)
    end
  end
end
