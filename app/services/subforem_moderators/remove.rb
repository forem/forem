module SubforemModerators
  class Remove
    def self.call(user, subforem)
      user.remove_role(:subforem_moderator, subforem)
      if user.notification_setting.email_community_mod_newsletter?
        user.notification_setting.update(email_community_mod_newsletter: false)
      end
      Rails.cache.delete("user-#{user.id}/subforem_moderators_list")
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




