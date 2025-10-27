module SubforemModerators
  class Add
    Result = Struct.new(:success?, :errors, keyword_init: true)

    def self.call(user_id, subforem_id)
      new(user_id, subforem_id).call
    end

    def initialize(user_id, subforem_id)
      @user_id = user_id
      @subforem_id = subforem_id
    end

    def call
      user = User.find(user_id)
      notification_setting = user.notification_setting
      if notification_setting.update(email_community_mod_newsletter: true)
        subforem = Subforem.find(subforem_id)
        add_subforem_mod_role(user, subforem)
        ::SubforemModerators::AddTrustedRole.call(user)

        NotifyMailer
          .with(user: user, subforem: subforem)
          .subforem_moderator_confirmation_email
          .deliver_now

        Result.new(success?: true)
      else
        Result.new(success?: false, errors: notification_setting.errors_as_sentence)
      end
    end

    private

    attr_accessor :user_id, :subforem_id

    def add_subforem_mod_role(user, subforem)
      unless user.notification_setting.email_community_mod_newsletter?
        user.notification_setting.update(email_community_mod_newsletter: true)
      end
      user.add_role(:subforem_moderator, subforem)
      Rails.cache.delete("user-#{user.id}/subforem_moderators_list")
      return unless community_mod_newsletter_enabled?

      Mailchimp::Bot.new(user).manage_community_moderator_list
    end

    def community_mod_newsletter_enabled?
      Settings::General.mailchimp_api_key.present? &&
        Settings::General.mailchimp_community_moderators_id.present?
    end
  end
end




