module HCaptcha
  class Verify
    ENDPOINT = "https://api.hcaptcha.com/siteverify".freeze

    def self.call(token:)
      return false unless token.is_a?(String) && token.present?
      return false if Settings::Authentication.hcaptcha_site_key.blank? ||
        Settings::Authentication.hcaptcha_secret_key.blank?

      response = HTTParty.post(
        ENDPOINT,
        body: {
          secret: Settings::Authentication.hcaptcha_secret_key, response: token,
          sitekey: Settings::Authentication.hcaptcha_site_key
        },
        timeout: 5,
        follow_redirects: false,
      )
      return false unless response.code == 200

      result = JSON.parse(response.body)
      result.is_a?(Hash) && result["success"] == true
    rescue JSON::ParserError, HTTParty::Error, Timeout::Error, SocketError, SystemCallError, OpenSSL::SSL::SSLError,
           IOError
      false
    end
  end
end
