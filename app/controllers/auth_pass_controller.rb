class AuthPassController < ApplicationController
  EMPTY_IFRAME_HTML = "<html><body></body></html>".html_safe
  AUTHENTICATED_IFRAME_HTML = <<~HTML.chomp.freeze
    <!-- In app/views/auth/iframe.html.erb -->
    <script>
      (function() {
        var data = {
          authenticated: true,
          token: '%<token>s'
        };

        // Send the message to the parent window
        window.parent.postMessage(data, '*');
      })();
    </script>
  HTML

  # Skip CSRF protection and unrelated page-navigation callbacks for auth_pass endpoints
  skip_before_action :verify_authenticity_token,
                     :verify_private_forem,
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

    if (session_current_user_id || cookies[:remember_user_token].present?) &&
        user_signed_in? && user_not_signed_out?(current_user)
      # User is authenticated on the main domain
      session[:user_id] = current_user.id
      @token = generate_auth_token(current_user)
    elsif session[:user_id]
      # User is authenticated via the iframe session cookie
      user = User.select(:id).find_by(id: session[:user_id])
      if user
        @token = generate_auth_token(user)
      else
        session.delete(:user_id)
        render html: EMPTY_IFRAME_HTML, status: :ok, layout: false
        return
      end
    elsif (main_session_user_id = request.cookie_jar.signed[:user_id])
      # Attempt to refresh the iframe session by checking main session
      user = User.select(:id).find_by(id: main_session_user_id)
      if user
        session[:user_id] = user.id
        @token = generate_auth_token(user)
      else
        request.session_options[:skip] = true
        render html: EMPTY_IFRAME_HTML, status: :ok, layout: false
        return
      end
    else
      request.session_options[:skip] = true
      render body: EMPTY_IFRAME_HTML, content_type: "text/html", status: :ok
      return
    end

    # Set headers to allow the iframe to be embedded
    response.headers["X-Frame-Options"] = "ALLOWALL"

    render body: format(AUTHENTICATED_IFRAME_HTML, token: @token), content_type: "text/html", status: :ok
  end

  def token_login
    token = params[:token]
    payload = decode_auth_token(token)

    if payload && payload["user_id"]
      user = User.find_by(id: payload["user_id"])
      if user && user_not_signed_out?(user)
        # Sign the user in
        session[:user_id] = user.id
    
        # Set remember_created_at and remember_token
        user.remember_me!
        # Get Devise’s default cookie values
        base_values = Devise::Controllers::Rememberable.cookie_values
        # Dynamically adjust the domain to match the request domain
        custom_domain = root_domain(request.host)
        adjusted_values = base_values.merge!(domain: custom_domain)
        # Set the actual remember cookie values as Devise does
        cookie_values = adjusted_values.merge!(
          value: user.class.serialize_into_cookie(user),
          expires: user.remember_expires_at
        )
        # Set the cookie with the dynamically adjusted domain
        cookies.signed["remember_user_token"] = cookie_values

        cookies[:forem_user_signed_in] = {
          value: "true",
          domain: ".#{custom_domain}",
          httponly: true,
          secure: ApplicationConfig["FORCE_SSL_IN_RAILS"] == "true",
          expires: 2.year.from_now
        }

        render json: { success: true, user: { id: user.id, email: user.email } }
      else
        render json: { success: false, error: "User not found" }, status: :unauthorized
      end
    else
      render json: { success: false, error: "Invalid or expired token" }, status: :unauthorized
    end
  end

  private

  def set_iframe_csp
    parent_origin = params[:passed_domain].presence ||
      params[:parent_origin].presence ||
      request.headers["Referer"].presence
    return if parent_origin.blank?

    origin_host, normalized_origin = parse_origin_host_and_csp(parent_origin)
    return if origin_host.blank?

    allowed_domains = (Subforem.cached_all_domains + [Settings::General.app_domain]).compact.map(&:downcase)
    is_allowed = allowed_domains.include?(origin_host) ||
      OrgCustomDomainConstraint.custom_domain_org_for_host(origin_host).present?
    return unless is_allowed

    response.headers["Content-Security-Policy"] = "frame-ancestors 'self' #{normalized_origin}"
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
    exp = 5.minutes.from_now.to_i # Token expires in 5 minutes
    ForemNative.encode_hs256_jwt(user.id, exp, Rails.application.secret_key_base) ||
      JWT.encode({ user_id: user.id, exp: exp }, Rails.application.secret_key_base)
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

  def user_not_signed_out?(user)
    # This is just checking that they have not explicitely signed out lately.
    return true if user.current_sign_in_at.present?
    return true if user.last_sign_in_at.blank? && user.current_sign_in_at.blank? # User never signed out.

    false
  end
end
