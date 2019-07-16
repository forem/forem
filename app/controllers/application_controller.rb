class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception, prepend: true

  include Pundit

  def require_http_auth
    authenticate_or_request_with_http_basic do |username, password|
      username == ApplicationConfig["APP_NAME"] && password == ApplicationConfig["APP_PASSWORD"]
    end
  end

  def not_found
    raise ActiveRecord::RecordNotFound, "Not Found"
  end

  def not_authorized
    render json: "Error: not authorized", status: :unauthorized
    raise NotAuthorizedError, "Unauthorized"
  end

  def efficient_current_user_id
    session["warden.user.user.key"].flatten[0] if session["warden.user.user.key"].present?
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

    request.env["omniauth.origin"] || stored_location_for(resource) || "/dashboard"
  end

  def raise_banned
    raise "BANNED" if current_user&.banned
  end

  def internal_navigation?
    params[:i] == "i"
  end
  helper_method :internal_navigation?

  def valid_request_origin?
    # This manually does what it was supposed to do on its own.
    # We were getting this issue:
    # HTTP Origin header (https://dev.to) didn't match request.base_url (http://dev.to)
    # Not sure why, but once we work it out, we can delete this method.
    # We are at least secure for now.
    return if Rails.env.test?

    if request.referer.present?
      request.referer.start_with?(ApplicationConfig["APP_PROTOCOL"].to_s + ApplicationConfig["APP_DOMAIN"].to_s)
    else
      logger.info "**REQUEST ORIGIN CHECK** #{request.origin}"
      raise InvalidAuthenticityToken, NULL_ORIGIN_MESSAGE if request.origin == "null"

      request.origin.nil? || request.origin.gsub("https", "http") == request.base_url.gsub("https", "http")
    end
  end

  def set_no_cache_header
    response.headers["Cache-Control"] = "no-cache, no-store"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end

  def touch_current_user
    current_user.touch
  end
end
