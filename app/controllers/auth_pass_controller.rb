class AuthPassController < ApplicationController
  # Skip CSRF protection for specific actions if necessary
  skip_before_action :verify_authenticity_token, only: [:iframe, :token_login]

  # Use the iframe session store for specific actions
  before_action :allow_cross_origin_requests, only: [:iframe, :token_login]
  before_action :use_iframe_session_store, only: [:iframe]

  def iframe
    if user_signed_in?
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
      if user
        # Authenticate the user
        session[:user_id] = user.id
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
end
