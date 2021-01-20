class ProfilePinsController < ApplicationController
  before_action :authenticate_user!, only: %i[create update]

  def create
    @profile_pin = ProfilePin.new
    @profile_pin.profile_id = current_user.id
    @profile_pin.profile_type = "User"
    @profile_pin.pinnable_id = profile_pin_params[:pinnable_id].to_i
    @profile_pin.pinnable_type = "Article"
    if @profile_pin.save
      flash[:pins_success] = "📌 Pinned! (pinned posts display chronologically, 5 max)"
    else
      flash[:pins_error] = "You can only have five pins"
    end
    redirect_back(fallback_location: "/dashboard")
    bust_user_profile
  end

  def update
    # for removing pinnable
    current_user.profile_pins.where(id: params[:id]).first&.destroy
    bust_user_profile
    flash[:pins_success] = "🗑 Pin removed"
    redirect_back(fallback_location: "/dashboard")
  end

  private

  def profile_pin_params
    params.require(:profile_pin).permit(:pinnable_id)
  end

  def bust_user_profile
    EdgeCache::Bust.call(current_user.path)
    EdgeCache::Bust.call("#{current_user.path}?i=i")
  end
end
