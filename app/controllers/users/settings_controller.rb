module Users
  class SettingsController < ApplicationController
    before_action :check_suspended
    before_action :authenticate_user!
    after_action :verify_authorized

    ALLOWED_PARAMS = %i[disallow_subforem_reassignment
                        config_theme
                        config_font
                        config_navbar
                        content_preferences_input
                        display_announcements
                        display_sponsors
                        editor_version
                        experience_level
                        inbox_guidelines
                        inbox_type
                        permit_adjacent_sponsors].freeze

    def update
      authorize current_user, policy_class: UserPolicy
      users_setting = current_user.setting
      tab = params["users_setting"]["tab"] || "profile"

      if users_setting.update(users_setting_params)
        if users_setting.experience_level.present?
          cookies.permanent[:user_experience_level] = users_setting.experience_level.to_s
        end
        current_user.touch(:profile_updated_at)
        flash[:settings_notice] = I18n.t("users_controller.updated_config")
      else
        Honeycomb.add_field("error", users_setting.errors.messages.compact_blank)
        Honeycomb.add_field("errored", true)
        flash[:error] = users_setting.errors_as_sentence
      end
      redirect_to user_settings_path(tab)
    end

    private

    def users_setting_params
      params.require(:users_setting).permit(ALLOWED_PARAMS)
    end
  end
end
