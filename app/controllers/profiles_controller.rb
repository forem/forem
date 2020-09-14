class ProfilesController < ApplicationController
  before_action :authenticate_user!
  ALLOWED_USER_PARAMS = %i[
    email username profile_image
  ].freeze

  def update
    Profiles::Update.call(current_user, update_params)
  end

  private

  def update_params
    params.permit(profile: Profile.attributes!, user: ALLOWED_USER_PARAMS)
  end
end
