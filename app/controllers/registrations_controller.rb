class RegistrationsController < Devise::RegistrationsController
  prepend_before_action :require_no_authentication, only: []

  def new
    if user_signed_in?
      redirect_to root_path(signin: "true")
    else
      if URI(request.referer || "").host == URI(request.base_url).host
        store_location_for(:user, request.referer)
      end
      super
    end
  end
end
