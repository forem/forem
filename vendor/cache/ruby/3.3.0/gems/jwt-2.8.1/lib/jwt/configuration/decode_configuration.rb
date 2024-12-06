# frozen_string_literal: true

module JWT
  module Configuration
    class DecodeConfiguration
      attr_accessor :verify_expiration,
                    :verify_not_before,
                    :verify_iss,
                    :verify_iat,
                    :verify_jti,
                    :verify_aud,
                    :verify_sub,
                    :leeway,
                    :algorithms,
                    :required_claims

      def initialize
        @verify_expiration = true
        @verify_not_before = true
        @verify_iss = false
        @verify_iat = false
        @verify_jti = false
        @verify_aud = false
        @verify_sub = false
        @leeway = 0
        @algorithms = ['HS256']
        @required_claims = []
      end

      def to_h
        {
          verify_expiration: verify_expiration,
          verify_not_before: verify_not_before,
          verify_iss: verify_iss,
          verify_iat: verify_iat,
          verify_jti: verify_jti,
          verify_aud: verify_aud,
          verify_sub: verify_sub,
          leeway: leeway,
          algorithms: algorithms,
          required_claims: required_claims
        }
      end
    end
  end
end
