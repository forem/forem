module Turnstile
  class Verify
    ENDPOINT = "https://challenges.cloudflare.com/turnstile/v0/siteverify".freeze

    def self.call(token:, hostname:)
      return false unless token.is_a?(String) && token.present? && token.length <= 2048
      return false if Settings::Authentication.turnstile_site_key.blank? ||
        Settings::Authentication.turnstile_secret_key.blank?

      response = HTTParty.post(
        ENDPOINT,
        body: { secret: Settings::Authentication.turnstile_secret_key, response: token },
        timeout: 5,
        follow_redirects: false,
      )
      return false unless response.code == 200

      result = JSON.parse(response.body)
      result.is_a?(Hash) && result["success"] == true && result["hostname"] == hostname
    rescue JSON::ParserError, HTTParty::Error, Timeout::Error, SocketError, SystemCallError, OpenSSL::SSL::SSLError
      false
    end
  end
end
