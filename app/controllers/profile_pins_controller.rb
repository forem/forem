class ProfilePinsController < ApplicationController
  before_action :authenticate_user!, only: %i[create update]

  def create
    @profile_pin = ProfilePin.new
    @profile_pin.profile_id = current_user.id
    @profile_pin.profile_type = "User"
    @profile_pin.pinnable_id = profile_pin_params[:pinnable_id].to_i
    @profile_pin.pinnable_type = "Article"
    if @profile_pin.save
      flash[:success] = I18n.t("views.pins.pinned")
    else
      flash[:error] = I18n.t("views.pins.error")
    end
    redirect_back(fallback_location: "/dashboard")
    bust_user_profile
  end

  def update
    # for removing pinnable
    current_user.profile_pins.destroy_by(id: params[:id])
    bust_user_profile
    flash[:success] = I18n.t("views.pins.removed")
    redirect_back(fallback_location: "/dashboard")
  end

  private

  def profile_pin_params
    params.require(:profile_pin).permit(:pinnable_id)
  end

  def bust_user_profile
    cache_bust = EdgeCache::Bust.new
    cache_bust.call(current_user.path)
    cache_bust.call("#{current_user.path}?i=i")
  end
end
