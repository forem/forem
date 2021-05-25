module Users
  class SettingsController < ApplicationController
    ALLOWED_PARAMS = %i[id
                        config_theme
                        config_font
                        config_navbar
                        editor_version
                        experience_level
                        display_sponsors
                        permit_adjacent_sponsors
                        display_announcements
                        user_id].freeze

    def update
      users_setting = Users::Setting.find(params[:id])
      users_setting.assign_attributes(users_setting_params)

      if users_setting.save
        notice = "Your config has been updated. Refresh to see all changes."

        if users_setting.experience_level.present?
          cookies.permanent[:user_experience_level] =
            users_setting.experience_level.to_s
        end
        flash[:settings_notice] = notice
        # [@msarit]: double check if we still need to set the profile_updated_at
        # like we did in the user controller
        # users_setting.user.touch(:profile_updated_at)
      else
        Honeycomb.add_field("error", users_setting.errors.messages.reject { |_, v| v.empty? })
        Honeycomb.add_field("errored", true)
        flash[:error] = @user.errors.full_messages.join(", ")
      end
      redirect_to "/settings/customization"
    end

    private

    def users_setting_params
      params.require(:users_setting).permit(ALLOWED_PARAMS)
    end
  end
end
