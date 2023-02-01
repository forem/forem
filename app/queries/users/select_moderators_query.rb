module Users
  class SelectModeratorsQuery
    def self.call(...)
      new(...).call
    end

    def call
      User.with_role(:trusted).joins(:notification_setting)
        .where(last_reacted_at: 1.week.ago..)
        .where("last_moderation_notification < ?", 3.days.ago)
        .where(notification_setting: { mod_roundrobin_notifications: true })
    end
  end
end
