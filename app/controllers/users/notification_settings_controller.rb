module Users
  class NotificationSettingsController < ApplicationController
    before_action :raise_suspended
    before_action :authenticate_user!
    after_action :verify_authorized

    ALLOWED_PARAMS = %i[id
                        email_badge_notifications
                        email_comment_notifications
                        email_community_mod_newsletter
                        email_connect_messages
                        email_digest_periodic
                        email_follower_notifications
                        email_membership_newsletter
                        email_mention_notifications
                        email_newsletter
                        email_tag_mod_newsletter
                        email_unread_notifications
                        mobile_comment_notifications
                        mod_roundrobin_notifications
                        reaction_notifications
                        welcome_notifications].freeze

    def update
      authorize current_user, policy_class: UserPolicy

      if current_user.notification_setting.update(users_notification_setting_params)
        notice = "Your notification settings have been updated."

        flash[:settings_notice] = notice
      else
        Honeycomb.add_field("error", current_user.notification_setting.errors.messages.compact_blank)
        Honeycomb.add_field("errored", true)
        flash[:error] = current_user.notification_setting.errors_as_sentence
      end
      redirect_to user_settings_path(:notifications)
    end

    private

    def users_notification_setting_params
      params.require(:users_notification_setting).permit(ALLOWED_PARAMS)
    end
  end
end
