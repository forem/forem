class ProfilePreviewCardsController < ApplicationController
  layout false

  def show
    @user = User.eager_load(:profile, :setting).find(params[:id])
    set_cache_control_headers
    set_surrogate_key_header(*@user.profile_cache_keys)
  end
end
