class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception, prepend: true

  include SessionCurrentUser
  include ValidRequest
  include Pundit

  rescue_from ActionView::MissingTemplate, with: :routing_error

  def require_http_auth
    authenticate_or_request_with_http_basic do |username, password|
      username == ApplicationConfig["APP_NAME"] && password == ApplicationConfig["APP_PASSWORD"]
    end
  end

  def not_found
    raise ActiveRecord::RecordNotFound, "Not Found"
  end

  def routing_error
    raise ActionController::RoutingError, "Routing Error"
  end

  def not_authorized
    render json: "Error: not authorized", status: :unauthorized
    raise NotAuthorizedError, "Unauthorized"
  end

  def authenticate_user!
    return if current_user

    respond_to do |format|
      format.html { redirect_to "/enter" }
      format.json { render json: { error: "Please sign in" }, status: :unauthorized }
    end
  end

  def customize_params
    params[:signed_in] = user_signed_in?.to_s
  end

  def after_sign_in_path_for(resource)
    return "/onboarding?referrer=#{request.env['omniauth.origin'] || 'none'}" unless current_user.saw_onboarding

    (request.env["omniauth.origin"] || stored_location_for(resource) || "/dashboard") + "?signin=true" # This signin=true param is used by frontend
  end

  def raise_banned
    raise "BANNED" if current_user&.banned
  end

  def internal_navigation?
    params[:i] == "i"
  end
  helper_method :internal_navigation?

  def set_no_cache_header
    response.headers["Cache-Control"] = "no-cache, no-store"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end

  def touch_current_user
    current_user.touch
  end
end
