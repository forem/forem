module Users
  class NotificationSetting < ApplicationRecord
    self.table_name_prefix = "users_"
    validates :email_digest_periodic, inclusion: { in: [true, false] }

    alias_attribute :subscribed_to_welcome_notifications?, :welcome_notifications
    alias_attribute :subscribed_to_mod_roundrobin_notifications?, :mod_roundrobin_notifications
    alias_attribute :subscribed_to_email_follower_notifications?, :email_follower_notifications

    # NOTE: @ridhwana Need to account for
    # subscribe_to_mailchimp_newsletter in app/models/user.rb
    # code: return unless saved_changes.key?(:email) || saved_changes.key?(:email_newsletter)
  end
end
