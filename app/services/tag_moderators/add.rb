module TagModerators
  class Add
    Result = Struct.new(:success?, :errors, keyword_init: true)

    def self.call(user_id, tag_id)
      new(user_id, tag_id).call
    end

    def initialize(user_id, tag_id)
      @user_id = user_id
      @tag_id = tag_id
    end

    def call
      user = User.find(user_id)
      notification_setting = user.notification_setting
      if notification_setting.update(email_tag_mod_newsletter: true)
        tag = Tag.find(tag_id)
        add_tag_mod_role(user, tag)
        ::TagModerators::AddTrustedRole.call(user)
        tag.update(supported: true) unless tag.supported?

        NotifyMailer
          .with(user: user, tag: tag)
          .tag_moderator_confirmation_email
          .deliver_now

        Result.new(success?: true)
      else
        Result.new(success?: false, errors: notification_setting.errors_as_sentence)
      end
    end

    private

    attr_accessor :user_id, :tag_id

    def add_tag_mod_role(user, tag)
      unless user.notification_setting.email_tag_mod_newsletter?
        user.notification_setting.update(email_tag_mod_newsletter: true)
      end
      user.add_role(:tag_moderator, tag)
      Rails.cache.delete("user-#{user.id}/tag_moderators_list")
      return unless tag_mod_newsletter_enabled?

      Mailchimp::Bot.new(user).manage_tag_moderator_list
    end

    def tag_mod_newsletter_enabled?
      Settings::General.mailchimp_api_key.present? &&
        Settings::General.mailchimp_tag_moderators_id.present?
    end
  end
end
