module Users
  #  @note When we destroy the related user, it's using dependent:
  #        :delete for the relationship.  That means no before/after
  #        destroy callbacks will be called on this object.
  class NotificationSetting < ApplicationRecord
    self.table_name_prefix = "users_"

    belongs_to :user, touch: true

    validates :email_digest_periodic, inclusion: { in: [true, false] }

    alias_attribute :subscribed_to_welcome_notifications, :welcome_notifications
    alias_attribute :subscribed_to_email_follower_notifications, :email_follower_notifications

    after_commit :subscribe_to_mailchimp_newsletter
    after_commit :track_email_consent_changes, on: :update
    after_save if: :saved_change_to_email_newsletter? do
      user&.sync_base_email_eligible!
    end

    def subscribe_to_mailchimp_newsletter
      return if Settings::General.mailchimp_api_key.blank?
      return unless saved_changes.key?(:email_newsletter)
      return if user.email.blank?

      Users::SubscribeToMailchimpNewsletterWorker.perform_async(user.id)
    end

    private

    # Email consent changes must reach MLH Core (source of truth for email
    # subscriptions), which cannot see this table otherwise. Fires on every
    # toggle path: settings page, one-click unsubscribe links, onboarding, and
    # the Mailchimp unsubscribe webhook.
    #
    # The newsletter and the periodic digest are SEPARATE consents — EmailDigest
    # selects on email_digest_periodic alone and never reads email_newsletter —
    # so each needs its own signal. A save that flips both emits both events.
    def track_email_consent_changes
      track_newsletter_change
      track_digest_change
    end

    def track_newsletter_change
      return unless saved_change_to_email_newsletter?

      event = email_newsletter? ? "user_newsletter_subscribed" : "user_newsletter_unsubscribed"
      user&.track!(event)
    end

    def track_digest_change
      return unless saved_change_to_email_digest_periodic?

      event = email_digest_periodic? ? "user_digest_subscribed" : "user_digest_unsubscribed"
      user&.track!(event)
    end
  end
end
