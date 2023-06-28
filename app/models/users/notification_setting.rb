module Users
  #  @note When we destroy the related user, it's using dependent:
  #        :delete for the relationship.  That means no before/after
  #        destroy callbacks will be called on this object.
  class NotificationSetting < ApplicationRecord
    self.table_name_prefix = "users_"
    self.ignored_columns += %w[email_connect_messages]

    belongs_to :user, touch: true

    validates :email_digest_periodic, inclusion: { in: [true, false] }

    alias_attribute :subscribed_to_welcome_notifications?, :welcome_notifications
    alias_attribute :subscribed_to_email_follower_notifications?, :email_follower_notifications

    after_commit :subscribe_to_mailchimp_newsletter

    def subscribe_to_mailchimp_newsletter
      return if Settings::General.mailchimp_api_key.blank?
      return unless saved_changes.key?(:email_newsletter)
      return if user.email.blank?

      Users::SubscribeToMailchimpNewsletterWorker.perform_async(user.id)
    end
  end
end
