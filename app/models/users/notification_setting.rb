module Users
  #  @note When we destroy the related user, it's using dependent:
  #        :delete for the relationship.  That means no before/after
  #        destroy callbacks will be called on this object.
  class NotificationSetting < ApplicationRecord
    self.table_name_prefix = "users_"

    # Every email consent MLH Core mirrors (onto a Customer.io subscription
    # topic or a Core newsletter key), mapped to the base name of the events
    # Core matches on the wire.
    #
    # The two original entries produce "user_newsletter_*" and "user_digest_*" —
    # NOT the column names. Core matches these strings exactly, so renaming one
    # silently breaks live consent sync; add entries, never rewrite these two.
    EMAIL_CONSENT_EVENTS = {
      email_newsletter: "newsletter",
      email_digest_periodic: "digest",
      email_comment_notifications: "comment_notifications",
      email_follower_notifications: "follower_notifications",
      email_mention_notifications: "mention_notifications",
      email_unread_notifications: "unread_notifications",
      email_badge_notifications: "badge_notifications",
      # Moderator newsletters land on Core's newsletter_subscriptions
      # dev_tag_mod / dev_community_mod keys (which Customer.io sends from).
      email_tag_mod_newsletter: "tag_mod_newsletter",
      email_community_mod_newsletter: "community_mod_newsletter"
    }.freeze
    # Emitted to Core but never written back by it: these follow the tag /
    # subforem moderator role (TagModerators::Add, SubforemModerators::Add,
    # Moderator::ManageActivityAndRoles), so DEV owns them one-way.
    ROLE_DRIVEN_NEWSLETTER_SETTINGS = %i[email_tag_mod_newsletter email_community_mod_newsletter].freeze
    # The user's own choices — the settings Core may push back through the
    # admin API (Api::Admin::UsersController#update_notification_settings).
    CORE_SYNCED_EMAIL_SETTINGS = (EMAIL_CONSENT_EVENTS.keys - ROLE_DRIVEN_NEWSLETTER_SETTINGS).freeze

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
    # Each entry in EMAIL_CONSENT_EVENTS is a SEPARATE consent — the digest, for
    # instance, is not the newsletter: EmailDigest selects on
    # email_digest_periodic alone and never reads email_newsletter — so each
    # needs its own signal. A save that flips several emits one event per flip.
    def track_email_consent_changes
      consenting_user = user
      return if consenting_user.nil?

      EMAIL_CONSENT_EVENTS.each do |column, name|
        next unless saved_change_to_attribute?(column)

        state = public_send(column) ? "subscribed" : "unsubscribed"
        consenting_user.track!("user_#{name}_#{state}")
      end
    end
  end
end
