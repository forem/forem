module SubforemModerators
  class AddTrustedRole
    def self.call(user)
      return if user.has_trusted_role? || user.spam_or_suspended?

      user.add_role(:trusted)
      user.notification_setting.update(email_community_mod_newsletter: true)
      NotifyMailer.with(user: user).trusted_role_email.deliver_now
      return unless community_mod_newsletter_enabled?

      Mailchimp::Bot.new(user).manage_community_moderator_list
    end

    def self.community_mod_newsletter_enabled?
      Settings::General.mailchimp_api_key.present? &&
        Settings::General.mailchimp_community_moderators_id.present?
    end
    private_class_method :community_mod_newsletter_enabled?
  end
end




