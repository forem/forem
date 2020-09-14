class ProfilesController < ApplicationController
  before_action :authenticate_user!
  ALLOWED_USER_PARAMS = %i[
    email username profile_image
  ].freeze

  def update
    update_result = Profiles::Update.call(current_user, update_params)
    if update_result.success?
      flash[:success] = "Your profile has been updated"
    else
      flash[:error] = "Error: #{update_result.error_message}"
    end
  end

  private

  def update_params
    params.permit(profile: Profile.attributes!, user: ALLOWED_USER_PARAMS)
  end
end
