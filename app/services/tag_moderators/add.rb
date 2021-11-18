module TagModerators
  class Add
    def self.call(user_ids, tag_ids)
      new(user_ids, tag_ids).call
    end

    def initialize(user_ids, tag_ids)
      @user_ids = user_ids
      @tag_ids = tag_ids
    end

    def call
      user_ids.each_with_index do |user_id, index|
        user = User.find(user_id)
        tag = Tag.find(tag_ids[index])
        add_tag_mod_role(user, tag)
        ::TagModerators::AddTrustedRole.call(user)
        tag.update(supported: true) unless tag.supported?

        NotifyMailer
          .with(user: user, tag: tag)
          .tag_moderator_confirmation_email
          .deliver_now
      end
    end

    private

    attr_accessor :user_ids, :tag_ids

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
