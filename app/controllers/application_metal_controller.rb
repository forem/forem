class ApplicationMetalController < ActionController::Metal
  # Any shared behavior across metal-oriented controllers can go here.

  # These are basic things we likely want for any metal controllers
  include ActionController::Cookies
  include ActionController::RequestForgeryProtection
  # ActionController modules which may not be used in each controller can go in
  # the specific controller.

  protect_from_forgery with: :exception, prepend: true unless Rails.env.test?

  include SessionCurrentUser
  include ValidRequest

  def logger
    ActionController::Base.logger
  end

  def client_geolocation
    if session_current_user_id
      request.headers["X-Client-Geo"]
    else
      request.headers["X-Cacheable-Client-Geo"]
    end
  end
  helper_method :client_geolocation

  def current_user_by_token
    auth_header = request.headers["Authorization"]
    return unless auth_header || params[:jwt]

    if auth_header.present? && auth_header.start_with?("Bearer ")
      token = auth_header.split(" ").last
      payload = decode_auth_token(token)
    elsif params[:jwt].present?
      token = params[:jwt]
      payload = decode_auth_token(token)
    end
    return unless payload && payload["user_id"]

    user = User.find_by(id: payload["user_id"])
    if user
      @current_user = user
      @token_authenticated = true
    end
  end

  def token_authenticated?
    @token_authenticated
  end

  def decode_auth_token(token)
    JWT.decode(token, Rails.application.secret_key_base, true, algorithm: "HS256")[0]
  rescue JWT::ExpiredSignature
    nil
  rescue
    nil
  end
end
