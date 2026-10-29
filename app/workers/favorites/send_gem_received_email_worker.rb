module Favorites
  class SendGemReceivedEmailWorker
    include Sidekiq::Job
    include Sidekiq::Throttled::Job

    FAVORITABLE_TYPES = %w[Article Comment].freeze

    sidekiq_throttle(concurrency: { limit: 8 })

    sidekiq_options queue: :low_priority, retry: 10

    def perform(favoritable_type, favoritable_id)
      return unless FAVORITABLE_TYPES.include?(favoritable_type)

      favoritable = favoritable_type.constantize.find_by(id: favoritable_id)
      return unless favoritable&.favorited_by_user_id

      user = favoritable.user
      # Gems are part of the badge system, so they share its email preference.
      return unless user&.email.present? && user.notification_setting.email_badge_notifications

      NotifyMailer.with(favoritable: favoritable).gem_received_email.deliver_now
    end
  end
end
