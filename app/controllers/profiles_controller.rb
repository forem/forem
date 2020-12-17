class ProfilesController < ApplicationController
  before_action :authenticate_user!
  ALLOWED_USER_PARAMS = %i[name email username profile_image].freeze

  def update
    update_result = Profiles::Update.call(current_user, update_params)
    if update_result.success?
      flash[:settings_notice] = "Your profile has been updated"
    else
      flash[:error] = "Error: #{update_result.errors_as_sentence}"
    end
    redirect_to user_settings_path
  end

  private

  def update_params
    params.permit(profile: Profile.attributes, user: ALLOWED_USER_PARAMS)
  end
end
