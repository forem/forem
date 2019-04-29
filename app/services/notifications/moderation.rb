module Notifications
  module Moderation
    MODERATORS_AVAILABILITY_DELAY = 28.hours
    SUPPORTED = [Comment].freeze

    def self.available_moderators
      User.with_role(:trusted).where("last_moderation_notification < ?", MODERATORS_AVAILABILITY_DELAY.ago)
    end
  end
end
