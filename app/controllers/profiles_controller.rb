class ProfilesController < ApplicationController
  before_action :authenticate_user!
  ALLOWED_USER_PARAMS = %i[email username profile_image].freeze

  def update
    update_result = Profiles::Update.call(current_user, update_params)
    if update_result.success?
      update_cookie_experience_level
      flash[:settings_notice] = "Your profile has been updated"
    else
      flash[:error] = "Error: #{update_result.error_message}"
    end
    redirect_to user_settings_path
  end

  private

  def update_params
    params.permit(profile: Profile.attributes!, user: ALLOWED_USER_PARAMS)
  end

  def update_cookie_experience_level
    return if current_user.experience_level.blank?

    cookies.permanent[:user_experience_level] = current_user.experience_level.to_s
  end
end
