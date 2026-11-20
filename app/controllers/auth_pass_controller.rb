class AuthPassController < ApplicationController
  EMPTY_IFRAME_HTML = "<html><body></body></html>".freeze
  AUTHENTICATED_IFRAME_HTML = <<~HTML.chomp.freeze
    <!-- In app/views/auth/iframe.html.erb -->
    <script>
      (function() {
        var data = {
          authenticated: true,
          token: '%<token>s'
        };

        // Send the message to the parent window
        window.parent.postMessage(data, %<target_origin>s);
      })();
    </script>
  HTML
  AUTHENTICATED_WEBVIEW_IFRAME_HTML = <<~HTML.chomp.freeze
    <!-- In app/views/auth/iframe.html.erb -->
    <script>
      (function() {
        var data = {
          authenticated: true,
          token: '%<token>s',
          mobileToken: '%<mobile_token>s'
        };

        // Send the message to the parent window
        window.parent.postMessage(data, %<target_origin>s);
      })();
    </script>
  HTML

  # Skip CSRF protection and unrelated page-navigation callbacks for auth_pass endpoints
  skip_before_action :verify_authenticity_token,
                     :remember_cookie_sync,
                     :forward_to_app_config_domain,
                     :redirect_custom_domain_non_profile_pages,
                     :determine_locale,
                     :set_request_signed_in_context,
                     only: %i[iframe token_login]

  # Use the iframe session store for specific actions
  before_action :allow_cross_origin_requests, only: %i[iframe token_login]
  before_action :use_iframe_session_store, only: [:iframe]
  before_action :set_iframe_csp, only: [:iframe]

  def iframe
    allowed_hosts = (Subforem.cached_all_domains + [Settings::General.app_domain]).compact.uniq
    unless allowed_hosts.include?(request.host)
      request.session_options[:skip] = true
      render plain: "Unauthorized", status: :unauthorized
      return
    end

    unless @parent_origin_allowed
      render_empty_iframe
      return
    end

    user = resolve_iframe_user
    return if performed? || user.nil?

    @token = generate_auth_token(user)
    target_origin = ERB::Util.json_escape((@target_origin || request.base_url).to_json)

    body = if request.user_agent == "ForemWebView/1"
             mobile_token = Authentication::AuthToken.encode_mobile_api(user)
             format(
               AUTHENTICATED_WEBVIEW_IFRAME_HTML,
               token: @token,
               mobile_token: mobile_token,
               target_origin: target_origin,
             )
           else
             format(AUTHENTICATED_IFRAME_HTML, token: @token, target_origin: target_origin)
           end

    render body: body,
           content_type: "text/html",
           status: :ok
  end

  def token_login
    response.headers["Cache-Control"] = "no-store"
    response.headers["Surrogate-Control"] = "no-store"

    token = params[:token]
    payload = Authentication::AuthToken.decode_auth_pass(token)

    if payload && payload["user_id"]
      user = User.find_by(id: payload["user_id"])
      if user && user_not_signed_out?(user) &&
          Authentication::AuthToken.valid_for_user?(payload, user, require_salt: true) &&
          Authentication::AuthToken.consume_auth_pass_jti!(payload)
        # Sign the user in
        session[:user_id] = user.id

        # Set remember_created_at and remember_token
        user.remember_me!
        # Get Devise’s default cookie values without mutating the shared hash
        custom_domain = root_domain(request.host)
        cookie_values = Devise::Controllers::Rememberable.cookie_values.merge(
          domain: custom_domain,
          value: user.class.serialize_into_cookie(user),
          expires: user.remember_expires_at,
        )
        # Set the cookie with the dynamically adjusted domain
        cookies.signed["remember_user_token"] = cookie_values

        cookies[:forem_user_signed_in] = {
          value: "true",
          domain: custom_domain == "localhost" ? nil : ".#{custom_domain}",
          httponly: true,
          secure: ApplicationConfig["FORCE_SSL_IN_RAILS"] == "true",
          expires: 2.years.from_now
        }

        render json: { success: true, user: { id: user.id, email: user.email } }
      else
        render json: { success: false, error: "Invalid or expired token" }, status: :unauthorized
      end
    else
      render json: { success: false, error: "Invalid or expired token" }, status: :unauthorized
    end
  end

  private

  def resolve_iframe_user
    if (session_current_user_id || cookies[:remember_user_token].present?) &&
        user_signed_in? && user_not_signed_out?(current_user) && !current_user.access_locked?
      session[:user_id] = current_user.id
      current_user
    elsif session[:user_id]
      user = find_active_iframe_user(session[:user_id])
      return user if user

      session.delete(:user_id)
      render_empty_iframe(skip_session: false)
    elsif (main_session_user_id = request.cookie_jar.signed[:user_id])
      user = find_active_iframe_user(main_session_user_id)
      if user
        session[:user_id] = user.id
        return user
      end

      render_empty_iframe
    else
      render_empty_iframe
    end
  end

  def render_empty_iframe(skip_session: true)
    request.session_options[:skip] = true if skip_session
    render body: EMPTY_IFRAME_HTML, content_type: "text/html", status: :ok
    nil
  end

  def set_iframe_csp
    response.headers["Content-Security-Policy"] = "frame-ancestors 'self'"
    response.headers["X-Frame-Options"] = "SAMEORIGIN"
    response.headers["Cache-Control"] = "no-store"
    response.headers["Surrogate-Control"] = "no-store"
    @parent_origin_allowed = true
    @target_origin = request.base_url

    parent_origin = params[:passed_domain].presence ||
      params[:parent_origin].presence ||
      request.headers["Referer"].presence
    return if parent_origin.blank?

    origin_host, normalized_origin = parse_origin_host_and_csp(parent_origin)
    if origin_host.blank?
      @parent_origin_allowed = false
      return
    end

    allowed_domains = (Subforem.cached_all_domains + [Settings::General.app_domain]).compact.map(&:downcase)
    is_allowed = allowed_domains.include?(origin_host) ||
      OrgCustomDomainConstraint.custom_domain_org_for_host(origin_host).present?
    unless is_allowed
      @parent_origin_allowed = false
      return
    end

    @target_origin = normalized_origin
    response.headers["Content-Security-Policy"] = "frame-ancestors 'self' #{normalized_origin}"
    response.headers.delete("X-Frame-Options")
  end

  def use_iframe_session_store
    return if Rails.env.test? # Skip Redis session setup in test environment

    request.session_options[:key] = Rails.application.config.iframe_session_options[:key]
    request.session_options[:same_site] = Rails.application.config.iframe_session_options[:same_site]
    request.session_options[:secure] = Rails.application.config.iframe_session_options[:secure]
    request.session_options[:path] = Rails.application.config.iframe_session_options[:path]
    request.session_options[:expire_after] = Rails.application.config.iframe_session_options[:expire_after]
    request.session_options[:httponly] = Rails.application.config.iframe_session_options[:httponly]
  end

  def generate_auth_token(user)
    Authentication::AuthToken.encode_auth_pass(user)
  end

  def allow_cross_origin_requests
    requesting_origin = request.headers["Origin"]
    return if requesting_origin.blank?

    origin_host, = parse_origin_host_and_csp(requesting_origin)
    return if origin_host.blank?

    allowed_domains = (Subforem.cached_domains + [Settings::General.app_domain]).compact.map(&:downcase)
    is_allowed = allowed_domains.include?(origin_host) ||
      OrgCustomDomainConstraint.custom_domain_org_for_host(origin_host).present?
    return unless is_allowed

    headers["Access-Control-Allow-Origin"] = requesting_origin
    headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
    headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization"
    headers["Access-Control-Allow-Credentials"] = "true"
  end

  def parse_origin_host_and_csp(raw_origin)
    ForemNative.parse_auth_pass_origin(raw_origin) || legacy_parse_origin_host_and_csp(raw_origin)
  end

  def legacy_parse_origin_host_and_csp(raw_origin)
    uri = begin
      URI.parse(raw_origin)
    rescue StandardError
      nil
    end
    origin_host = uri&.host&.downcase || raw_origin.gsub(%r{https?://}, "").split(":").first&.downcase
    return if origin_host.blank?

    scheme = (uri&.scheme || "https").downcase
    scheme = "https" unless %w[http https].include?(scheme)
    host = (uri&.host || origin_host).downcase
    port_suffix = uri&.port && [80, 443].exclude?(uri.port) ? ":#{uri.port}" : ""
    [origin_host, "#{scheme}://#{host}#{port_suffix}"]
  end

  def find_active_iframe_user(user_id)
    user = User.select(:id, :current_sign_in_at, :last_sign_in_at, :encrypted_password, :locked_at).find_by(id: user_id)
    user if user && user_not_signed_out?(user) && !user.access_locked?
  end

  def user_not_signed_out?(user)
    # This is just checking that they have not explicitely signed out lately.
    return true if user.current_sign_in_at.present?
    return true if user.last_sign_in_at.blank? && user.current_sign_in_at.blank? # User never signed out.

    false
  end
end
