require "base64"
require "json"
require "openssl"

module EdgeFeed
  # HMAC-SHA256 token signer/verifier shared between Rails and the Fastly Compute
  # edge feed service (`forem_core::edge_feed`).
  #
  # Token wire format:
  #   <prefix>.<base64url(payload_json)>.<base64url(HMAC-SHA256(secret, "<prefix>.<base64url(payload_json)>"))>
  class TokenSigner
    USER_TOKEN_PREFIX = "eu1".freeze
    STICKY_CONFIG_TOKEN_PREFIX = "ec1".freeze
    VISIT_TOKEN_PREFIX = "ev1".freeze

    USER_COOKIE_NAME = :_forem_edge_uid
    STICKY_CONFIG_COOKIE_NAME = :_forem_edge_fc
    DEFAULT_USER_COOKIE_TTL = 7.days
    MAX_TOKEN_BYTES = 4096

    class << self
      def configured?
        secret.present?
      end

      def secret
        ApplicationConfig["FASTLY_EDGE_FEED_SECRET"].to_s
      end

      def sign(prefix:, payload:, secret: self.secret)
        raise ArgumentError, "FASTLY_EDGE_FEED_SECRET is not configured" if secret.blank?

        encoded_payload = Base64.urlsafe_encode64(payload.to_s, padding: false)
        signing_input = "#{prefix}.#{encoded_payload}"
        mac = OpenSSL::HMAC.digest("SHA256", secret, signing_input)
        encoded_mac = Base64.urlsafe_encode64(mac, padding: false)
        "#{signing_input}.#{encoded_mac}"
      end

      def verify(prefix:, token:, secret: self.secret)
        return if secret.blank? || !token.is_a?(String) || token.bytesize > MAX_TOKEN_BYTES

        parts = token.split(".", -1)
        return unless parts.length == 3 && parts[0] == prefix

        signing_input = "#{parts[0]}.#{parts[1]}"
        expected_mac = OpenSSL::HMAC.digest("SHA256", secret, signing_input)
        provided_mac = safe_base64url_decode(parts[2])
        return unless provided_mac && provided_mac.bytesize == expected_mac.bytesize
        return unless ActiveSupport::SecurityUtils.secure_compare(provided_mac, expected_mac)

        safe_base64url_decode(parts[1])&.force_encoding(Encoding::UTF_8)
      end

      def issue_user_token(user_id:, ttl: DEFAULT_USER_COOKIE_TTL, now: Time.current, secret: self.secret)
        exp = now.to_i + ttl.to_i
        payload = JSON.generate({ uid: user_id.to_i, exp: exp })
        sign(prefix: USER_TOKEN_PREFIX, payload: payload, secret: secret)
      end

      def verify_user_token(token, now: Time.current, secret: self.secret)
        raw = verify(prefix: USER_TOKEN_PREFIX, token: token, secret: secret)
        return unless raw

        data = parse_json(raw)
        return unless data.is_a?(Hash)

        uid = data["uid"]
        exp = data["exp"]
        return unless uid.is_a?(Integer) && uid.positive? && exp.is_a?(Integer) && exp > now.to_i

        uid
      end

      def issue_visit_token(user_id:, subforem_id:, feed_config_id:, expires_at:, host:, secret: self.secret)
        payload = JSON.generate(
          {
            user_id: user_id.to_i,
            subforem_id: subforem_id.to_i,
            feed_config_id: feed_config_id.to_i,
            expires_at: expires_at.to_i,
            host: host.to_s
          },
        )
        sign(prefix: VISIT_TOKEN_PREFIX, payload: payload, secret: secret)
      end

      def verify_visit_token(token, now: Time.current, secret: self.secret)
        raw = verify(prefix: VISIT_TOKEN_PREFIX, token: token, secret: secret)
        return unless raw

        data = parse_json(raw)
        return unless data.is_a?(Hash)

        exp = data["expires_at"]
        return unless data["user_id"].is_a?(Integer) &&
          data["subforem_id"].is_a?(Integer) &&
          data["feed_config_id"].is_a?(Integer) &&
          exp.is_a?(Integer) &&
          exp > now.to_i &&
          data["host"].is_a?(String) &&
          data["host"].present?

        {
          "user_id" => data["user_id"],
          "subforem_id" => data["subforem_id"],
          "feed_config_id" => data["feed_config_id"],
          "expires_at" => Time.zone.at(exp).utc,
          "host" => data["host"]
        }
      end

      def set_user_cookie(cookies, user_id:, secure: Rails.env.production?)
        return unless configured? && user_id.present?

        cookies[USER_COOKIE_NAME] = {
          value: issue_user_token(user_id: user_id),
          httponly: true,
          same_site: :lax,
          secure: secure,
          expires: DEFAULT_USER_COOKIE_TTL.from_now
        }
      end

      def clear_user_cookie(cookies)
        cookies.delete(USER_COOKIE_NAME)
        cookies.delete(STICKY_CONFIG_COOKIE_NAME)
      end

      private

      def safe_base64url_decode(str)
        return unless str.is_a?(String) && str.match?(/\A[A-Za-z0-9\-_]+\z/)

        Base64.urlsafe_decode64(str)
      rescue ArgumentError
        nil
      end

      def parse_json(raw)
        return unless raw.valid_encoding?

        JSON.parse(raw)
      rescue JSON::ParserError
        nil
      end
    end
  end
end
