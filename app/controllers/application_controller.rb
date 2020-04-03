class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception, prepend: true

  include SessionCurrentUser
  include ValidRequest
  include Pundit

  rescue_from ActionView::MissingTemplate, with: :routing_error

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

  def bad_request
    render json: "Error: Bad Request", status: :bad_request
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
    if current_user.saw_onboarding
      path = request.env["omniauth.origin"] || stored_location_for(resource) || dashboard_path
      signin_param = { "signin" => "true" } # the "signin" param is used by the service worker

      uri = Addressable::URI.parse(path)
      uri.query_values = if uri.query_values
                           uri.query_values.merge(signin_param)
                         else
                           signin_param
                         end

      uri.to_s
    else
      referrer = request.env["omniauth.origin"] || "none"
      onboarding_path(referrer: referrer)
    end
  end

  def raise_suspended
    raise "SUSPENDED" if current_user&.banned
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

  # The following is from the now deprecated fastly-rails gem
  # https://github.com/fastly/fastly-rails/tree/master/lib/fastly-rails/action_controller

  # Sets Cache-Control and Surrogate-Control HTTP headers
  # Surrogate-Control is stripped at the cache, Cache-Control persists (in case of other caches in front of fastly)
  # Defaults are:
  #  Cache-Control: 'public, no-cache'
  #  Surrogate-Control: 'max-age: 30 days
  # custom config example:
  #  {cache_control: 'public, no-cache, maxage=xyz', surrogate_control: 'max-age: blah'}
  def set_cache_control_headers(max_age = 1.day.to_i, opts = {})
    request.session_options[:skip] = true # no cookies
    response.headers["Cache-Control"] = opts[:cache_control] || "public, no-cache"
    response.headers["Surrogate-Control"] = opts[:surrogate_control] || build_surrogate_control(max_age, opts)
  end

  # Sets Surrogate-Key HTTP header with one or more keys
  # strips session data from the request
  def set_surrogate_key_header(*surrogate_keys)
    request.session_options[:skip] = true # No Set-Cookie
    response.headers["Surrogate-Key"] = surrogate_keys.join(" ")
  end

  private

  def build_surrogate_control(max_age, opts)
    surrogate_control = "max-age=#{max_age}"
    stale_while_revalidate = opts[:stale_while_revalidate]
    stale_if_error = opts[:stale_if_error] || 26_400

    surrogate_control += ", stale-while-revalidate=#{stale_while_revalidate}" if stale_while_revalidate
    surrogate_control += ", stale-if-error=#{stale_if_error}" if stale_if_error
    surrogate_control
  end
end
