module Users
  class NotificationSettingsController < ApplicationController
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
                        welcome_notifications
                        user_id].freeze

    def update
      users_notification_setting = Users::NotificationSetting.find(params[:id])
      users_notification_setting.assign_attributes(users_notification_setting_params)

      if users_notification_setting.save
        notice = "Your notification settings have been updated."

        flash[:settings_notice] = notice
      else
        Honeycomb.add_field("error", users_notification_setting.errors.messages.reject { |_, v| v.empty? })
        Honeycomb.add_field("errored", true)
        flash[:error] = @users_notification_setting.errors.full_messages.join(", ")
      end
      redirect_to "/settings/notifications"
    end

    private

    def users_notification_setting_params
      params.require(:users_notification_setting).permit(ALLOWED_PARAMS)
    end
  end
end
