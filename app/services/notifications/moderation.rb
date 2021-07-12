module Notifications
  module Moderation
    MODERATORS_AVAILABILITY_DELAY = 22.hours
    SUPPORTED = [Comment].freeze

    def self.available_moderators
      User.with_role(:trusted).joins(:notification_setting)
        .where("last_moderation_notification < ?", 3.days.ago)
        .where(notification_setting: { mod_roundrobin_notifications: true })
    end
  end
end
