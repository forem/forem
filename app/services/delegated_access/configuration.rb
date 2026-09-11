require "uri"

require_relative "jwks_client"
require_relative "verifier"

module DelegatedAccess
  class Configuration
    DEFAULT_JWKS_MAX_AGE_SECONDS = 300
    DEFAULT_MAX_TOKEN_LIFETIME_SECONDS = 60
    REGISTERED_CLAIMS = %w[iss sub aud exp nbf iat jti client_id scope nonce sid].freeze
    private_constant :DEFAULT_JWKS_MAX_AGE_SECONDS, :DEFAULT_MAX_TOKEN_LIFETIME_SECONDS, :REGISTERED_CLAIMS

    attr_reader :audience, :enabled, :identity_provider, :issuer, :jwks_uri, :owner_claim, :verifier

    def self.from_env(env = ENV)
      enabled_value = env.fetch("DELEGATED_ACCESS_ENABLED", "false")
      unless %w[true false].include?(enabled_value)
        raise ArgumentError, "DELEGATED_ACCESS_ENABLED must be true or false"
      end

      return new(enabled: false) if enabled_value == "false"

      issuer = required(env, "DELEGATED_ACCESS_ISSUER")
      audience = required(env, "DELEGATED_ACCESS_AUDIENCE")
      identity_provider = required(env, "DELEGATED_ACCESS_IDENTITY_PROVIDER")
      owner_claim = required(env, "DELEGATED_ACCESS_OWNER_CLAIM")
      jwks_uri = required(env, "DELEGATED_ACCESS_JWKS_URI")

      validate_https_uri!(issuer, "DELEGATED_ACCESS_ISSUER")
      parsed_jwks_uri = validate_https_uri!(jwks_uri, "DELEGATED_ACCESS_JWKS_URI", path_required: true)
      validate_owner_claim!(owner_claim)

      jwks_max_age = positive_integer(
        env,
        "DELEGATED_ACCESS_JWKS_MAX_AGE_SECONDS",
        DEFAULT_JWKS_MAX_AGE_SECONDS,
      )
      maximum_token_lifetime = positive_integer(
        env,
        "DELEGATED_ACCESS_MAX_TOKEN_LIFETIME_SECONDS",
        DEFAULT_MAX_TOKEN_LIFETIME_SECONDS,
      )
      verifier = Verifier.new(
        issuer: issuer,
        audience: audience,
        owner_claim: owner_claim,
        jwks_client: JwksClient.new(uri: parsed_jwks_uri),
        maximum_token_lifetime: maximum_token_lifetime,
        jwks_cache_lifetime: jwks_max_age,
      )

      new(
        enabled: true,
        issuer: issuer,
        audience: audience,
        identity_provider: identity_provider,
        owner_claim: owner_claim,
        jwks_uri: jwks_uri,
        verifier: verifier,
      )
    end

    def initialize(enabled:, issuer: nil, audience: nil, identity_provider: nil, owner_claim: nil,
                   jwks_uri: nil, verifier: nil)
      @enabled = enabled
      @issuer = issuer
      @audience = audience
      @identity_provider = identity_provider
      @owner_claim = owner_claim
      @jwks_uri = jwks_uri
      @verifier = verifier
    end

    def invalidate_cache!
      verifier&.invalidate_cache!
    end

    class << self
      private

      def required(env, name)
        value = env.fetch(name)
        raise ArgumentError, "#{name} must not be blank" if value.blank?

        value.dup.freeze
      end

      def positive_integer(env, name, default)
        value = Integer(env.fetch(name, default.to_s), 10)
        raise ArgumentError, "#{name} must be positive" unless value.positive?

        value
      rescue ArgumentError
        raise ArgumentError, "#{name} must be a positive integer"
      end

      def validate_https_uri!(value, name, path_required: false)
        uri = URI.parse(value)
        valid = uri.is_a?(URI::HTTPS) && uri.host.present? && uri.userinfo.nil? && uri.query.nil? && uri.fragment.nil?
        valid &&= uri.path.present? && uri.path != "/" if path_required
        raise ArgumentError, "#{name} must be an HTTPS URI" unless valid

        uri.freeze
      rescue URI::InvalidURIError
        raise ArgumentError, "#{name} must be an HTTPS URI"
      end

      def validate_owner_claim!(owner_claim)
        validate_https_uri!(owner_claim, "DELEGATED_ACCESS_OWNER_CLAIM", path_required: true)
        return unless REGISTERED_CLAIMS.include?(owner_claim)

        raise ArgumentError, "DELEGATED_ACCESS_OWNER_CLAIM must be collision-resistant"
      end
    end
  end
end
