# Helpers for request specs that drive a full OmniAuth round trip and then
# continue with the same session (Redis-backed sessions need the cookie
# forwarded explicitly between requests).
module OmniauthSessionHelpers
  def follow_session_cookie
    cookie = response.headers["Set-Cookie"].to_s.split("\n").map { |c| c.split(";").first }.join("; ")
    @session_cookie = cookie.presence if cookie.present?
  end

  def session_headers
    @session_cookie ? { "Cookie" => @session_cookie } : {}
  end

  def get_with_session(path, params: {})
    get path, params: params, headers: session_headers
    follow_session_cookie
  end

  def post_with_session(path)
    post path, headers: session_headers
    follow_session_cookie
  end

  # Runs the request phase and the callback phase for +provider+ with the
  # given mocked payload; +params+ are sent with the initiating request.
  def omniauth_sign_in(provider, payload, params: {})
    OmniAuth.config.mock_auth[provider.to_sym] = payload
    get_with_session "/users/auth/#{provider}", params: params
    get_with_session "/users/auth/#{provider}/callback"
  end

  def signed_in_user_id
    session["warden.user.user.key"].to_a.flatten.map(&:to_s).first&.to_i
  end
end
