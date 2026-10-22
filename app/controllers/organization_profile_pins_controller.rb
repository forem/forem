class OrganizationProfilePinsController < ApplicationController
  include OrganizationAdminScoped

  def create
    @profile_pin = ProfilePin.new(
      profile_id: @organization.id,
      profile_type: "Organization",
      pinnable_id: profile_pin_params[:pinnable_id].to_i,
      pinnable_type: "Article",
    )

    if @profile_pin.save
      flash[:success] = I18n.t("views.pins.pinned")
    else
      flash[:error] = @profile_pin.errors.full_messages.to_sentence.presence || I18n.t("views.pins.error")
    end

    bust_organization_page
    redirect_back(fallback_location: @organization.path)
  end

  def destroy
    @organization.profile_pins.destroy_by(id: params[:id])
    bust_organization_page
    flash[:success] = I18n.t("views.pins.removed")
    redirect_back(fallback_location: @organization.path)
  end

  private

  def profile_pin_params
    params.require(:profile_pin).permit(:pinnable_id)
  end

  def bust_organization_page
    cache_bust = EdgeCache::Bust.new
    cache_bust.call(@organization.path)
    cache_bust.call("#{@organization.path}?i=i")
  end
end
