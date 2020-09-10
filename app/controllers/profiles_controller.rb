class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def update
    Profiles::Update.call(current_user.profile, update_params)
  end

  private

  def update_params
    params.require(:profile).permit(*Profile.attributes)
  end
end
