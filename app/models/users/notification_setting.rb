module Users
  class NotificationSetting < ApplicationRecord
    self.table_name_prefix = "users_"

    belongs_to :user, touch: true

    validates :email_digest_periodic, inclusion: { in: [true, false] }

    alias_attribute :subscribed_to_welcome_notifications?, :welcome_notifications
    alias_attribute :subscribed_to_mod_roundrobin_notifications?, :mod_roundrobin_notifications
    alias_attribute :subscribed_to_email_follower_notifications?, :email_follower_notifications

    after_commit :subscribe_to_mailchimp_newsletter

    def subscribe_to_mailchimp_newsletter
      return unless email_newsletter

      Users::SubscribeToMailchimpNewsletterWorker.perform_async(user.id)
    end
  end
end
