class ProfilesController < ApplicationController
  before_action :authenticate_user!

  ALLOWED_USER_PARAMS = %i[name email username profile_image].freeze
  ALLOWED_USERS_SETTING_PARAMS = %i[display_email_on_profile brand_color1 brand_color2].freeze

  def update
    update_result = Profiles::Update.call(current_user, update_params)
    if update_result.success?
      flash[:settings_notice] = "Your profile has been updated"
      redirect_to user_settings_path
    else
      @user = current_user
      @tab = "profile"
      flash[:error] = "Error: #{update_result.errors_as_sentence}"
      render template: "users/edit", locals: {
        user: update_params[:user],
        profile: update_params[:profile],
        users_setting: update_params[:users_setting]
      }
    end
  end

  private

  def update_params
    params.permit(profile: Profile.attributes + Profile.static_fields,
                  user: ALLOWED_USER_PARAMS,
                  users_setting: ALLOWED_USERS_SETTING_PARAMS)
  end
end
