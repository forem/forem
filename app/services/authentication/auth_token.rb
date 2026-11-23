module Authentication
  class AuthToken
    AUTH_PASS_PURPOSE = "auth_pass".freeze
    MOBILE_API_PURPOSE = "mobile_api".freeze
    AUTH_PASS_EXPIRY = 5.minutes
    AUTH_PASS_MAX_TTL_SKEW = 60.seconds
    MOBILE_API_EXPIRY = 30.days
    AUTH_PASS_KEY_SALT = "auth-pass-token".freeze
    REVOCATION_CACHE_KEY_PREFIX = "user_tokens_revoked_at_ms".freeze
    USED_JTI_CACHE_KEY_PREFIX = "auth_pass_token:used".freeze

    class << self
      def encode_auth_pass(user)
        now_time = Time.current
        now_sec = now_time.to_i
        payload = {
          user_id: user.id,
          exp: now_sec + AUTH_PASS_EXPIRY.to_i,
          iat: now_sec,
          iat_ms: timestamp_ms(now_time),
          jti: SecureRandom.uuid,
          purpose: AUTH_PASS_PURPOSE,
          salt: salt_fingerprint(user)
        }
        JWT.encode(payload, auth_pass_secret, "HS256")
      end

      def decode_auth_pass(token)
        return unless token.is_a?(String) && token.present?

        payload = verify_jwt(token, auth_pass_secret)
        return unless valid_auth_pass_claims?(payload)

        payload
      end

      def consume_auth_pass_jti!(payload)
        jti = payload["jti"]
        return false unless jti.is_a?(String) && jti.present?

        claimed = Rails.cache.write(
          "#{USED_JTI_CACHE_KEY_PREFIX}:#{jti}",
          true,
          expires_in: AUTH_PASS_EXPIRY,
          unless_exist: true,
        )
        claimed != false
      end

      def encode_mobile_api(user)
        now_time = Time.current
        now_sec = now_time.to_i
        payload = {
          user_id: user.id,
          exp: now_sec + MOBILE_API_EXPIRY.to_i,
          iat: now_sec,
          iat_ms: timestamp_ms(now_time),
          purpose: MOBILE_API_PURPOSE,
          salt: salt_fingerprint(user)
        }
        JWT.encode(payload, Rails.application.secret_key_base, "HS256")
      end

      def extract_bearer_token(auth_header)
        return unless auth_header.is_a?(String) && auth_header.start_with?("Bearer ")

        token = auth_header.delete_prefix("Bearer ").strip
        token.presence
      end

      def valid_for_user?(payload, user, require_salt: false)
        return false unless payload.is_a?(Hash) && user.present?
        return false if user.has_attribute?(:locked_at) && user.locked_at.present?
        return false if signed_out_user?(user)

        if require_salt || payload["salt"].present?
          expected_salt = salt_fingerprint(user)
          token_salt = payload["salt"].to_s
          return false unless token_salt.bytesize == expected_salt.bytesize &&
            ActiveSupport::SecurityUtils.secure_compare(token_salt, expected_salt)
        end

        revoked_at_ms = revoked_at_ms_for(user.id)
        return false if revoked_at_ms.present? && !issued_after_revocation?(payload, revoked_at_ms)

        true
      end

      def revoke_for_user!(user_id)
        return if user_id.blank?

        Rails.cache.write(
          "#{REVOCATION_CACHE_KEY_PREFIX}:#{user_id}",
          timestamp_ms(Time.current),
          expires_in: MOBILE_API_EXPIRY,
        )
      end

      def revoked_at_for(user_id)
        revoked_at_ms_for(user_id)
      end

      def revoked_at_ms_for(user_id)
        Rails.cache.read("#{REVOCATION_CACHE_KEY_PREFIX}:#{user_id}")
      end

      def salt_fingerprint(user)
        Digest::SHA256.hexdigest(user.authenticatable_salt.to_s)[0, 16]
      end

      private

      def valid_auth_pass_claims?(payload)
        return false unless payload.is_a?(Hash) && payload["purpose"] == AUTH_PASS_PURPOSE
        return false unless payload["user_id"].present? && non_empty_string?(payload["jti"])
        return false unless non_empty_string?(payload["salt"])

        valid_auth_pass_timestamps?(payload)
      end

      def valid_auth_pass_timestamps?(payload)
        iat = payload["iat"]
        exp = payload["exp"]
        return false unless iat.is_a?(Integer) && exp.is_a?(Integer)

        exp > Time.current.to_i && exp <= iat + AUTH_PASS_EXPIRY.to_i + AUTH_PASS_MAX_TTL_SKEW.to_i
      end

      def non_empty_string?(value)
        value.is_a?(String) && value.present?
      end

      def signed_out_user?(user)
        return false unless user.has_attribute?(:current_sign_in_at) && user.has_attribute?(:last_sign_in_at)

        user.last_sign_in_at.present? && user.current_sign_in_at.blank?
      end

      def issued_after_revocation?(payload, revoked_at_ms)
        if payload["iat_ms"].is_a?(Integer)
          payload["iat_ms"] > revoked_at_ms
        elsif payload["iat"].is_a?(Integer)
          payload["iat"] > (revoked_at_ms / 1000)
        else
          false
        end
      end

      def timestamp_ms(time)
        (time.to_f * 1000).to_i
      end

      def auth_pass_secret
        base = Rails.application.secret_key_base
        if @cached_auth_pass_secret_base == base && @cached_auth_pass_secret
          return @cached_auth_pass_secret
        end

        @cached_auth_pass_secret = Rails.application.key_generator.generate_key(AUTH_PASS_KEY_SALT, 32)
        @cached_auth_pass_secret_base = base
        @cached_auth_pass_secret
      end

      def verify_jwt(token, secret)
        native = ForemNative.verify_hs256_jwt(token, secret, Time.now.to_i)
        return if native == false
        return native if native

        JWT.decode(token, secret, true, algorithm: "HS256")[0]
      rescue StandardError
        nil
      end
    end
  end
end
