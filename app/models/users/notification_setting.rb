module Users
  class NotificationSetting < ApplicationRecord
    self.table_name_prefix = "users_"
    validates :email_digest_periodic, inclusion: { in: [true, false] }

    alias_attribute :subscribed_to_welcome_notifications?, :welcome_notifications
    alias_attribute :subscribed_to_mod_roundrobin_notifications?, :mod_roundrobin_notifications
    alias_attribute :subscribed_to_email_follower_notifications?, :email_follower_notifications
  end
end
