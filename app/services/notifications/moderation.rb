module Notifications
  module Moderation
    MODERATORS_AVAILABILITY_DELAY = 22.hours
    SUPPORTED = [Comment].freeze

    def self.available_moderators
      # TODO: [@msarit] update query to call mod_roundrobin_notifications from correct table
      User.with_role(:trusted)
        .where("last_moderation_notification < ?", MODERATORS_AVAILABILITY_DELAY.ago)
        .where(mod_roundrobin_notifications: true)
    end
  end
end
