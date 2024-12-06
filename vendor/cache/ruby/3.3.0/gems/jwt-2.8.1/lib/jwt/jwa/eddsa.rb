# frozen_string_literal: true

module JWT
  module JWA
    module Eddsa
      SUPPORTED = %w[ED25519 EdDSA].freeze
      SUPPORTED_DOWNCASED = SUPPORTED.map(&:downcase).freeze

      class << self
        def sign(algorithm, msg, key)
          unless key.is_a?(RbNaCl::Signatures::Ed25519::SigningKey)
            raise EncodeError, "Key given is a #{key.class} but has to be an RbNaCl::Signatures::Ed25519::SigningKey"
          end

          validate_algorithm!(algorithm)

          key.sign(msg)
        end

        def verify(algorithm, public_key, signing_input, signature)
          unless public_key.is_a?(RbNaCl::Signatures::Ed25519::VerifyKey)
            raise DecodeError, "key given is a #{public_key.class} but has to be a RbNaCl::Signatures::Ed25519::VerifyKey"
          end

          validate_algorithm!(algorithm)

          public_key.verify(signature, signing_input)
        rescue RbNaCl::CryptoError
          false
        end

        private

        def validate_algorithm!(algorithm)
          return if SUPPORTED_DOWNCASED.include?(algorithm.downcase)

          raise IncorrectAlgorithm, "Algorithm #{algorithm} not supported. Supported algoritms are #{SUPPORTED.join(', ')}"
        end
      end
    end
  end
end
