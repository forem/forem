module Users
  #  @note When we destroy the related user, it's using dependent:
  #        :delete for the relationship.  That means no before/after
  #        destroy callbacks will be called on this object.
  class NotificationSetting < ApplicationRecord
    self.table_name_prefix = "users_"

    belongs_to :user, touch: true

    validates :email_digest_periodic, inclusion: { in: [true, false] }

    alias_attribute :subscribed_to_welcome_notifications?, :welcome_notifications
    alias_attribute :subscribed_to_email_follower_notifications?, :email_follower_notifications
    # TODO: add subscribed_to_new_post_notifications
    alias_attribute :subscribed_to_new_post_notifications?, :new_post_notifications

    after_commit :subscribe_to_mailchimp_newsletter

    def self.users_where_new_post_notification(user_ids, subscribed)
      where(id: user_ids, subscribed_to_new_post_notifications?: subscribed).distinct.select(:id)
    end

    def subscribe_to_mailchimp_newsletter
      return if Settings::General.mailchimp_api_key.blank?
      return unless saved_changes.key?(:email_newsletter)
      return if user.email.blank?

      Users::SubscribeToMailchimpNewsletterWorker.perform_async(user.id)
    end

  end
end
