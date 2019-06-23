class ProfilePinsController < ApplicationController
  before_action :authenticate_user!, only: %i[create]

  def create
    @profile_pin = ProfilePin.new
    @profile_pin.profile_id = current_user.id
    @profile_pin.profile_type = "User"
    @profile_pin.pinnable_id = profile_pin_params[:pinnable_id].to_i
    @profile_pin.pinnable_type = "Article"
    if @profile_pin.save!
      flash[:pins_success] = "📌 Pinned! (pinned posts display chronologically, 5 max)"
    else
      flash[:pins_error] = "You can only have five pins"
    end
    redirect_back(fallback_location: "/dashboard")
  end

  def update
    # for removing pinnable
    ProfilePin.find(params[:id]).destroy
    flash[:pins_success] = "🗑 Pin removed"
    redirect_back(fallback_location: "/dashboard")
  end

  private

  def profile_pin_params
    params.require(:profile_pin).permit(:pinnable_id)
  end
end
