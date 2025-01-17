class AuthPassController < ApplicationController
  # Skip CSRF protection for specific actions if necessary
  skip_before_action :verify_authenticity_token, only: [:iframe, :token_login]

  # Use the iframe session store for specific actions
  before_action :allow_cross_origin_requests, only: [:iframe, :token_login]
  before_action :use_iframe_session_store, only: [:iframe]

  def iframe
    unless Subforem.cached_all_domains.include?(request.host)
      render plain: "Unauthorized", status: :unauthorized
      return
    end

    if user_signed_in? && user_not_signed_out?(current_user)
      # User is authenticated on the main domain
      session[:user_id] = current_user.id
      @token = generate_auth_token(current_user)
    elsif session[:user_id]
      # User is authenticated via the iframe session cookie
      user = User.find_by(id: session[:user_id])
      if user
        @token = generate_auth_token(user)
      else
        session.delete(:user_id)
        render plain: "Unauthorized", status: :unauthorized
        return
      end
    else
      # Attempt to refresh the iframe session by checking main session
      if main_session_user_id = request.cookie_jar.signed[:user_id]
        user = User.find_by(id: main_session_user_id)
        if user
          session[:user_id] = user.id
          @token = generate_auth_token(user)
        else
          render plain: "Unauthorized", status: :unauthorized
          return
        end
      else
        render plain: "Unauthorized", status: :unauthorized
        return
      end
    end  

    # Set headers to allow the iframe to be embedded
    response.headers["X-Frame-Options"] = "ALLOWALL"

    render layout: false
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
    payload = {
      user_id: user.id,
      exp: 5.minutes.from_now.to_i # Token expires in 5 minutes
    }
    JWT.encode(payload, Rails.application.secret_key_base)
  end

  def decode_auth_token(token)
    JWT.decode(token, Rails.application.secret_key_base, true, algorithm: "HS256")[0]
  rescue JWT::ExpiredSignature
    nil
  rescue
    nil
  end

  def allow_cross_origin_requests
    allowed_domains = (ApplicationConfig["SECONDARY_APP_DOMAINS"].to_s.split(",") + [Settings::General.app_domain]).compact
    requesting_origin = request.headers["Origin"]

    if allowed_domains.present? && allowed_domains.include?(requesting_origin&.gsub(/https?:\/\//, ""))
      headers["Access-Control-Allow-Origin"] = requesting_origin
      headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
      headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization"
      headers["Access-Control-Allow-Credentials"] = "true"
    end
  end

  def user_not_signed_out?(user)
    # This is just checking that they have not explicitely signed out lately.
    return true if user.current_sign_in_at.present?
    return true if user.last_sign_in_at.blank? && user.current_sign_in_at.blank? # User never signed out.

    false
  end
end
