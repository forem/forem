class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  skip_before_action :track_ahoy_visit
  before_action :verify_private_forem
  protect_from_forgery with: :exception, prepend: true
  before_action :remember_cookie_sync
  before_action :forward_to_app_config_domain
  before_action :determine_locale

  include SessionCurrentUser
  include ValidRequest
  include Pundit::Authorization
  include CachingHeaders
  include ImageUploads
  include DevelopmentDependencyChecks if Rails.env.development?
  include EdgeCacheSafetyCheck unless Rails.env.production?
  include Devise::Controllers::Rememberable

  rescue_from ActionView::MissingTemplate, with: :routing_error

  rescue_from RateLimitChecker::LimitReached do |exc|
    error_too_many_requests(exc)
  end

  rescue_from ActionController::InvalidAuthenticityToken do
    ForemStatsClient.increment(
      "users.invalid_authenticity_token",
      tags: ["controller_name:#{controller_name}", "path:#{request.fullpath}"],
    )
  end

  rescue_from ApplicationPolicy::UserSuspendedError, with: :respond_with_user_suspended

  PUBLIC_CONTROLLERS = %w[async_info
                          confirmations
                          deep_links
                          ga_events
                          health_checks
                          instances
                          invitations
                          omniauth_callbacks
                          passwords
                          registrations
                          service_worker].freeze
  private_constant :PUBLIC_CONTROLLERS

  CONTENT_CHANGE_PATHS = [
    "/tags/onboarding", # Needs to change when suggested_tags is edited.
    "/onboarding", # Page is cached at edge.
    "/", # Page is cached at edge.
  ].freeze
  private_constant :CONTENT_CHANGE_PATHS

  # @!scope class
  # @!attribute [w] api_action
  #   If set to true, all actions on the class (and subclasses) will be considered "api_actions"
  #
  #   @param input [Boolean]
  #   @see ApplicationController#api_action?
  #   @see ApplicationController#verify_private_forem
  #   @see https://api.rubyonrails.org/classes/Class.html#method-i-class_attribute Class.class_attribute
  class_attribute :api_action, default: false, instance_writer: false

  # @!scope instance
  # @!attribute [r] api_action?
  #   By default, all actions are *not* an `api_action?`
  #   @return [TrueClass] if the current requested action is for the API
  #   @return [FalseClass] if the current requested action is not part of the API
  #   @see Api::V0::ApiController
  #   @see Api::V1::ApiController
  #   @see ApplicationController.api_action
  #   @see ApplicationController#verify_private_forem

  def verify_private_forem
    return if controller_name.in?(PUBLIC_CONTROLLERS)
    return if self.class.module_parent.to_s == "Admin"
    return if user_signed_in? || Settings::UserExperience.public

    if api_action?
      authenticate!
    elsif (@page = Page.landing_page)
      render template: "pages/show"
    else
      @user ||= User.new
      render template: "devise/registrations/new"
    end
  end

  # When called, raise ActiveRecord::RecordNotFound.
  #
  # @raise [ActiveRecord::RecordNotFound] when called
  def not_found
    raise ActiveRecord::RecordNotFound, "Not Found"
  end

  # When called, raise ActionController::RoutingError.
  # @raise [ActionController::RoutingError] when called
  def routing_error
    raise ActionController::RoutingError, "Routing Error"
  end

  # When called render unauthorized JSON status and raise Pundit::NotAuthorizedError
  #
  # @raise [Pundit::NotAuthorizedError]
  #
  # @note [@jeremyf] It's a little surprising that we both render a JSON response and raise an
  #       exception.
  def not_authorized
    render json: { error: I18n.t("application_controller.not_authorized") }, status: :unauthorized
    raise Pundit::NotAuthorizedError, "Unauthorized"
  end

  def bad_request
    render json: { error: I18n.t("application_controller.bad_request") }, status: :bad_request
  end

  def error_too_many_requests(exc)
    response.headers["Retry-After"] = exc.retry_after
    render json: { error: exc.message, status: 429 }, status: :too_many_requests
  end

  # This method is envisioned as a :before_action callback.
  #
  # @return [TrueClass] if we have a current_user
  # @return [FalseClass] if we don't have a current_user
  #
  # @see {#authenticate_user!} for when you want to raise an error if we don't have a current user.
  def authenticate_user
    return false unless current_user

    Honeycomb.add_field("current_user_id", current_user.id)
    true
  end

  # @deprecated Use {#authenticate_user} and #{ApplicationPolicy}.
  #
  # When we don't have a current user, render a response that prompts the requester to authenticate.
  # This function circumvents the work that should be done in the {ApplicationPolicy} layer.
  #
  # @return [TrueClass] if we have an authenticated user
  #
  # @note This method is envisioned as a :before_action callback.
  #
  # @see {#authenticate_user}
  # @see {ApplicationPolicy} for discussion around authentication and authorization.
  def authenticate_user!
    return true if authenticate_user

    respond_with_request_for_authentication
  end

  def respond_with_request_for_authentication
    respond_to do |format|
      format.html { redirect_to sign_up_path }
      format.json { render json: { error: I18n.t("application_controller.please_sign_in") }, status: :unauthorized }
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

  # @deprecated This is a policy related question and should be part of an ApplicationPolicy
  def check_suspended
    return unless current_user&.suspended?

    respond_with_user_suspended
  end

  def respond_with_user_suspended
    response.status = :forbidden
    render "pages/forbidden"
  end

  def internal_navigation?
    params[:i] == "i"
  end
  helper_method :internal_navigation?

  def feed_style_preference
    # TODO: Future functionality will let current_user override this value with UX preferences
    # if current_user exists and has a different preference.
    Settings::UserExperience.feed_style
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
    User.new(ip_address: request.env["HTTP_FASTLY_CLIENT_IP"] || request.env["HTTP_X_FORWARDED_FOR"])
  end

  def initialize_stripe
    Stripe.api_key = Settings::General.stripe_api_key

    return unless Rails.env.development? && Stripe.api_key.present?

    Stripe.log_level = Stripe::LEVEL_INFO
  end

  def determine_locale
    I18n.locale = if %w[en fr].include?(params[:locale])
                    params[:locale]
                  else
                    Settings::UserExperience.default_locale
                  end
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
    # Let's only redirect get requests for this purpose.
    return unless request.get? &&
      # If the request equals the original set domain, e.g. forem-x.forem.cloud.
      request.host == ENV["APP_DOMAIN"] &&
      # If the app domain config has now been set, let's go there instead.
      ENV["APP_DOMAIN"] != Settings::General.app_domain

    redirect_to URL.url(request.fullpath)
  end

  def bust_content_change_caches
    EdgeCache::Bust.call(CONTENT_CHANGE_PATHS)
    Settings::General.admin_action_taken_at = Time.current # Used as cache key
  end

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[username name profile_image profile_image_url])
    devise_parameter_sanitizer.permit(:accept_invitation, keys: %i[name])
  end

  def internal_nav_param
    return "" unless params[:i] == "i"

    "?i=i"
  end
end
