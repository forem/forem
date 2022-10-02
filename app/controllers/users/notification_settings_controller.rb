module Users
  class NotificationSettingsController < ApplicationController
    before_action :check_suspended
    before_action :authenticate_user!
    after_action :verify_authorized

    ALLOWED_PARAMS = %i[email_badge_notifications
                        email_comment_notifications
                        email_community_mod_newsletter
                        email_digest_periodic
                        email_follower_notifications
                        email_membership_newsletter
                        email_mention_notifications
                        email_newsletter
                        email_tag_mod_newsletter
                        email_unread_notifications
                        mobile_comment_notifications
                        mobile_mention_notifications
                        mod_roundrobin_notifications
                        reaction_notifications
                        welcome_notifications].freeze
    ONBOARDING_ALLOWED_PARAMS = %i[email_newsletter email_digest_periodic].freeze

    def update
      authorize current_user, policy_class: UserPolicy

      if current_user.notification_setting.update(users_notification_setting_params)
        flash[:settings_notice] = I18n.t("users_controller.notifications_settings_updated")
      else
        Honeycomb.add_field("error", current_user.notification_setting.errors.messages.compact_blank)
        Honeycomb.add_field("errored", true)
        flash[:error] = current_user.notification_setting.errors_as_sentence
      end
      redirect_to user_settings_path(:notifications)
    end

    def onboarding_notifications_checkbox_update
      authorize User

      if params[:notifications]
        current_user.notification_setting.assign_attributes(params[:notifications].permit(ONBOARDING_ALLOWED_PARAMS))
      end

      current_user.saw_onboarding = true
      success = current_user.notification_setting.save
      render_update_response(success, current_user.notification_setting.errors_as_sentence)
    end

    private

    def render_update_response(success, errors = nil)
      status = success ? 200 : 422

      respond_to do |format|
        format.json { render json: { errors: errors }, status: status }
      end
    end

    def users_notification_setting_params
      params.require(:users_notification_setting).permit(ALLOWED_PARAMS)
    end
  end
end
