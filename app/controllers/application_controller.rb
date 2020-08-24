class ApplicationController < ActionController::Base
  skip_before_action :track_ahoy_visit
  before_action :verify_private_forem
  protect_from_forgery with: :exception, prepend: true

  include SessionCurrentUser
  include ValidRequest
  include Pundit
  include CachingHeaders
  include ImageUploads
  include VerifySetupCompleted

  rescue_from ActionView::MissingTemplate, with: :routing_error

  rescue_from RateLimitChecker::LimitReached do |exc|
    error_too_many_requests(exc)
  end

  PUBLIC_CONTROLLERS = %w[shell async_info ga_events].freeze
  private_constant :PUBLIC_CONTROLLERS

  def verify_private_forem
    return if controller_name.in?(PUBLIC_CONTROLLERS)
    return if user_signed_in? || SiteConfig.public

    if api_action?
      authenticate!
    else
      render template: "devise/registrations/new"
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

  def bad_request
    render json: "Error: Bad Request", status: :bad_request
  end

  def error_too_many_requests(exc)
    response.headers["Retry-After"] = exc.retry_after
    render json: { error: exc.message, status: 429 }, status: :too_many_requests
  end

  def authenticate_user!
    if current_user
      Honeycomb.add_field("current_user_id", current_user.id)
      return
    end

    respond_to do |format|
      format.html { redirect_to "/enter" }
      format.json { render json: { error: "Please sign in" }, status: :unauthorized }
    end
  end

  def customize_params
    params[:signed_in] = user_signed_in?.to_s
  end

  # This method is used by Devise to decide which is the path to redirect
  # the user to after a successful log in
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

  def feed_style_preference
    # TODO: Future functionality will let current_user override this value with UX preferences
    # if current_user exists and has a different preference.
    SiteConfig.feed_style
  end
  helper_method :feed_style_preference

  def set_no_cache_header
    response.headers["Cache-Control"] = "no-cache, no-store"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end

  def rate_limit!(action)
    rate_limiter.check_limit!(action)
  end

  def rate_limiter
    (current_user || anonymous_user).rate_limiter
  end

  def anonymous_user
    User.new(ip_address: request.env["HTTP_FASTLY_CLIENT_IP"])
  end

  def api_action?
    self.class.to_s.start_with?("Api::")
  end

  def initialize_stripe
    Stripe.api_key = SiteConfig.stripe_api_key

    return unless Rails.env.development? && Stripe.api_key.present?

    Stripe.log_level = Stripe::LEVEL_INFO
  end
end
