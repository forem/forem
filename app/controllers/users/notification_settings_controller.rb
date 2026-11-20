module Users
  class NotificationSettingsController < ApplicationController
    before_action :check_suspended
    before_action :authenticate_user!
    after_action :verify_authorized

    ALLOWED_PARAMS = Users::NotificationSetting::BOOLEAN_ATTRIBUTES
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

    private

    def render_update_response(success, errors = nil)
      status = success ? 200 : 422

      respond_to do |format|
        format.json { render json: { errors: errors }, status: status }
      end
    end

    def users_notification_setting_params
      raw_params = params.require(:users_notification_setting)
      raise ActionController::ParameterMissing, :users_notification_setting unless raw_params.respond_to?(:permit)

      boolean_type = ActiveModel::Type::Boolean.new
      raw_params.permit(ALLOWED_PARAMS).to_h.transform_values do |value|
        cast = boolean_type.cast(value)
        cast.nil? ? false : cast
      end
    end
  end
end
