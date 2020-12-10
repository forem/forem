class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  skip_before_action :track_ahoy_visit
  before_action :verify_private_forem
  protect_from_forgery with: :exception, prepend: true
  before_action :remember_cookie_sync
  before_action :forward_to_app_config_domain

  include SessionCurrentUser
  include ValidRequest
  include Pundit
  include CachingHeaders
  include ImageUploads
  include VerifySetupCompleted
  include DevelopmentDependencyChecks if Rails.env.development?
  include EdgeCacheSafetyCheck unless Rails.env.production?
  include Devise::Controllers::Rememberable

  rescue_from ActionView::MissingTemplate, with: :routing_error

  rescue_from RateLimitChecker::LimitReached do |exc|
    error_too_many_requests(exc)
  end

  PUBLIC_CONTROLLERS = %w[shell
                          async_info
                          ga_events
                          service_worker
                          omniauth_callbacks
                          registrations
                          confirmations
                          invitations
                          passwords
                          health_checks].freeze
  private_constant :PUBLIC_CONTROLLERS

  def verify_private_forem
    return if controller_name.in?(PUBLIC_CONTROLLERS)
    return if self.class.module_parent.to_s == "Admin"
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
      format.html { redirect_to sign_up_path }
      format.json { render json: { error: "Please sign in" }, status: :unauthorized }
    end
  end

  def redirect_permanently_to(location)
    redirect_to location + internal_nav_param, status: :moved_permanently
  end

  def customize_params
    params[:signed_in] = user_signed_in?.to_s
  end

  # This method is used by Devise to decide which is the path to redirect
  # the user to after a successful log in
  def after_sign_in_path_for(resource)
    if current_user.saw_onboarding
      path = stored_location_for(resource) || request.env["omniauth.origin"] || root_path(signin: "true")
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

  def after_accept_path_for(_resource)
    onboarding_path
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

  def remember_cookie_sync
    # Set remember cookie token in case not properly set.
    if user_signed_in? &&
        cookies[:remember_user_token].blank?
      current_user.remember_me = true
      current_user.remember_me!
      remember_me(current_user)
    end
  end

  def forward_to_app_config_domain
    return unless request.get? && # Let's only redirect get requests for this purpose.
      request.host == ENV["APP_DOMAIN"] && # If the request equals the original set domain, e.g. forem-x.forem.cloud.
      ENV["APP_DOMAIN"] != SiteConfig.app_domain # If the app domain config has now been set, let's go there instead.

    redirect_to URL.url(request.fullpath)
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[username name profile_image profile_image_url])
  end

  def internal_nav_param
    return "" unless params[:i] == "i"

    "?i=i"
  end
end
