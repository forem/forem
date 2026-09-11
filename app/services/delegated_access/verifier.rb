require "json"
require "jwt"
require "openssl"

require_relative "errors"
require_relative "jwks_client"

module DelegatedAccess
  class Verifier
    Claims = Struct.new(:subject, :owner_id, keyword_init: true)

    MAX_TOKEN_BYTES = 16_384
    MAX_KEYS = 32
    MAX_KID_BYTES = 128
    MAX_STRING_CLAIM_BYTES = 256
    CLOCK_SKEW_SECONDS = 5
    REQUIRED_CLAIMS = %w[iss sub aud exp iat nbf jti].freeze
    FORBIDDEN_PURPOSE_CLAIMS = %w[nonce sid].freeze
    HEADER_MEMBERS = %w[alg kid typ].freeze
    PRIVATE_RSA_PARAMETERS = %w[d p q dp dq qi oth].freeze
    CACHE_KEY = :delegated_access_jwks
    private_constant :MAX_TOKEN_BYTES, :MAX_KEYS, :MAX_KID_BYTES, :MAX_STRING_CLAIM_BYTES,
                     :CLOCK_SKEW_SECONDS, :REQUIRED_CLAIMS, :FORBIDDEN_PURPOSE_CLAIMS,
                     :HEADER_MEMBERS, :PRIVATE_RSA_PARAMETERS, :CACHE_KEY

    ClaimError = Class.new(StandardError)
    InvalidJwks = Class.new(StandardError)
    private_constant :ClaimError, :InvalidJwks

    def initialize(issuer:, audience:, owner_claim:, jwks_client:, maximum_token_lifetime:,
                   jwks_cache_lifetime:, cache: ActiveSupport::Cache::MemoryStore.new)
      @issuer = issuer
      @audience = audience
      @owner_claim = owner_claim
      @jwks_client = jwks_client
      @maximum_token_lifetime = maximum_token_lifetime
      @jwks_cache_lifetime = jwks_cache_lifetime
      @cache = cache
    end

    def verify(token)
      validate_token!(token)
      _payload, header = JWT.decode(token, nil, false)
      validate_header!(header)

      payload, = JWT.decode(
        token,
        nil,
        true,
        algorithms: ["RS256"],
        jwks: method(:load_jwks),
        iss: issuer,
        verify_iss: true,
        aud: audience,
        verify_aud: true,
        required_claims: REQUIRED_CLAIMS + [owner_claim],
        verify_expiration: true,
        verify_not_before: true,
        verify_iat: true,
        leeway: CLOCK_SKEW_SECONDS,
      )
      claims = validate_claims(payload)
      record(:accepted)
      claims
    rescue Errors::Unavailable
      raise
    rescue JWT::DecodeError, JWT::JWKError, JSON::ParserError, ArgumentError, TypeError, ClaimError
      record(:rejected)
      raise Errors::InvalidToken
    end

    def invalidate_cache!
      cache.delete(CACHE_KEY)
    end

    private

    attr_reader :audience, :cache, :issuer, :jwks_cache_lifetime, :jwks_client,
                :maximum_token_lifetime, :owner_claim

    def validate_token!(token)
      raise ClaimError, "invalid token" unless token.is_a?(String) && token.bytesize <= MAX_TOKEN_BYTES
    end

    def validate_header!(header)
      raise ClaimError, "invalid protected header" unless header.is_a?(Hash) && header.keys.sort == HEADER_MEMBERS
      raise ClaimError, "wrong token purpose" unless header["alg"] == "RS256" && header["typ"] == "at+jwt"
      raise ClaimError, "invalid key ID" unless bounded_string(header["kid"], maximum_bytes: MAX_KID_BYTES)
    end

    def load_jwks(_options)
      cache_hit = true
      jwks = cache.fetch(CACHE_KEY, expires_in: jwks_cache_lifetime) do
        cache_hit = false
        record(:refresh)
        parse_jwks(jwks_client.fetch)
      end
      record(:cache_hit) if cache_hit
      jwks
    rescue JwksClient::Error, InvalidJwks
      record(:unavailable_jwks)
      raise Errors::Unavailable
    end

    def parse_jwks(document)
      parsed = JSON.parse(document)
      signing_keys = validated_signing_keys(parsed)

      jwks = JWT::JWK::Set.new("keys" => signing_keys)
      jwks.select! { |jwk| eligible_key?(jwk) }
      raise InvalidJwks, "JWKS has no eligible signing keys" unless jwks.any?

      jwks.freeze
    rescue JSON::ParserError, JWT::JWKError, OpenSSL::PKey::PKeyError, ArgumentError, TypeError => e
      raise InvalidJwks, e.message
    end

    def validated_signing_keys(parsed)
      raw_keys = parsed["keys"] if parsed.is_a?(Hash)
      raise InvalidJwks, "JWKS must contain keys" unless raw_keys.is_a?(Array) && raw_keys.any?
      raise InvalidJwks, "JWKS contains too many keys" if raw_keys.size > MAX_KEYS
      raise InvalidJwks, "JWKS keys must be objects" unless raw_keys.all?(Hash)
      raise InvalidJwks, "JWKS contains private key material" if raw_keys.any? { |key| private_key?(key) }

      signing_keys = raw_keys.select { |key| signing_key?(key) }
      raise InvalidJwks, "JWKS has no eligible signing keys" unless signing_keys.any?

      key_ids = signing_keys.pluck("kid")
      raise InvalidJwks, "JWKS contains duplicate key IDs" unless key_ids.uniq.size == key_ids.size

      signing_keys
    end

    def private_key?(key)
      key.is_a?(Hash) && (key.keys & PRIVATE_RSA_PARAMETERS).any?
    end

    def signing_key?(key)
      key["kty"] == "RSA" && key["use"] == "sig" && key["alg"] == "RS256" &&
        bounded_string(key["kid"], maximum_bytes: MAX_KID_BYTES)
    end

    def eligible_key?(jwk)
      verification_key = jwk.verify_key
      verification_key.is_a?(OpenSSL::PKey::RSA) && verification_key.public? &&
        verification_key.n.num_bits >= 2048 && verification_key.e.odd? && verification_key.e >= 3
    rescue JWT::JWKError, OpenSSL::PKey::PKeyError, ArgumentError, TypeError
      false
    end

    def validate_claims(payload)
      raise ClaimError, "invalid claims" unless payload.is_a?(Hash)
      raise ClaimError, "invalid audience" unless payload["aud"] == audience
      raise ClaimError, "wrong token purpose" if FORBIDDEN_PURPOSE_CLAIMS.any? { |claim| payload.key?(claim) }

      subject = bounded_string(payload["sub"])
      raise ClaimError, "invalid subject" unless subject
      raise ClaimError, "invalid JWT ID" unless bounded_string(payload["jti"])

      validate_token_lifetime!(payload)
      owner_id = parse_owner_id(payload[owner_claim])
      Claims.new(subject: subject.freeze, owner_id: owner_id).freeze
    end

    def validate_token_lifetime!(payload)
      issued_at, not_before, expires_at = %w[iat nbf exp].map { |claim| payload[claim] }
      raise ClaimError, "invalid timestamps" unless [issued_at, not_before, expires_at].all?(Integer)

      lifetime = expires_at - issued_at
      raise ClaimError, "invalid lifetime" unless lifetime.positive? && lifetime <= maximum_token_lifetime
      raise ClaimError, "invalid not-before" if not_before > expires_at
    end

    def bounded_string(value, maximum_bytes: MAX_STRING_CLAIM_BYTES)
      value if value.is_a?(String) && value.present? && value.bytesize <= maximum_bytes
    end

    def parse_owner_id(value)
      raise ClaimError, "invalid owner" unless value.is_a?(String) && value.match?(/\A[1-9]\d{0,18}\z/)

      owner_id = Integer(value, 10)
      raise ClaimError, "invalid owner" if owner_id > 9_223_372_036_854_775_807

      owner_id
    end

    def record(outcome)
      ForemStatsClient.increment("delegated_access.verification", tags: ["outcome:#{outcome}"])
    rescue StandardError => e
      Rails.logger.warn("[DelegatedAccess] telemetry_error=#{e.class.name}")
    end
  end
end
