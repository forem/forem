# frozen_string_literal: true

module JWT
  module JWA
    module Rsa
      module_function

      SUPPORTED = %w[RS256 RS384 RS512].freeze

      def sign(algorithm, msg, key)
        unless key.is_a?(OpenSSL::PKey::RSA)
          raise EncodeError, "The given key is a #{key.class}. It has to be an OpenSSL::PKey::RSA instance"
        end

        key.sign(OpenSSL::Digest.new(algorithm.sub('RS', 'sha')), msg)
      end

      def verify(algorithm, public_key, signing_input, signature)
        public_key.verify(OpenSSL::Digest.new(algorithm.sub('RS', 'sha')), signature, signing_input)
      rescue OpenSSL::PKey::PKeyError
        raise JWT::VerificationError, 'Signature verification raised'
      end
    end
  end
end
