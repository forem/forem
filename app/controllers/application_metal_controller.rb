class ApplicationMetalController < ActionController::Metal
  # Any shared behavior across metal-oriented controllers can go here.

  # These are basic things we likely want for any metal controllers
  include ActionController::Cookies
  include ActionController::RequestForgeryProtection
  # ActionController modules which may not be used in each controller can go in
  # the specific controller.

  protect_from_forgery with: :exception, prepend: true unless Rails.env.test?
  after_action :skip_session_commit

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
      token = auth_header.split.last
      payload = decode_auth_token(token)
    elsif params[:jwt].present?
      token = params[:jwt]
      payload = decode_auth_token(token)
    end
    return unless payload && payload["user_id"]

    user = User.find_by(id: payload["user_id"])
    return unless user

    @current_user = user
    @token_authenticated = true
  end

  def token_authenticated?
    @token_authenticated
  end

  def decode_auth_token(token)
    native = ForemNative.verify_hs256_jwt(token, Rails.application.secret_key_base, Time.now.to_i)
    return if native == false
    return native if native

    legacy_decode_auth_token(token)
  end

  def valid_authenticity_token?(session, encoded_masked_token)
    return false if !encoded_masked_token.is_a?(String) || encoded_masked_token.empty?

    encoded_real_token = request.env[CSRF_TOKEN]
    if encoded_real_token.nil?
      fetched = csrf_token_storage_strategy.fetch(request)
      encoded_real_token = request.env[CSRF_TOKEN] = fetched if fetched
    end

    if encoded_real_token.is_a?(String)
      verified = if per_form_csrf_tokens
                   ForemNative.verify_authenticity_token(
                     encoded_masked_token,
                     encoded_real_token,
                     request.path,
                     request.request_method,
                   )
                 else
                   ForemNative.verify_authenticity_token(encoded_masked_token, encoded_real_token)
                 end
      return verified unless verified.nil?
    end

    super
  end

  private

  def legacy_decode_auth_token(token)
    JWT.decode(token, Rails.application.secret_key_base, true, algorithm: "HS256")[0]
  rescue JWT::ExpiredSignature
    nil
  rescue StandardError
    nil
  end

  # Metal controllers are read-only consumers of the session (CSRF verification
  # and session_current_user_id). Skipping Rack's post-request session commit
  # avoids a redundant Redis SETEX and Set-Cookie on every telemetry ping.
  # Must run as an after_action (not before_action): Rack::Session::Redis#find_session
  # returns an empty hash without reading Redis if options[:skip] is already true
  # when the session is first loaded.
  def skip_session_commit
    request.session_options[:skip] = true unless remembered_user_restored?
  end
end
