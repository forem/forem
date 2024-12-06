# frozen_string_literal: true

module JWT
  module Algos
    module HmacRbNaClFixed
      MAPPING   = { 'HS512256' => ::RbNaCl::HMAC::SHA512256 }.freeze
      SUPPORTED = MAPPING.keys

      class << self
        def sign(algorithm, msg, key)
          key ||= ''
          Deprecations.warning("The use of the algorithm #{algorithm} is deprecated and will be removed in the next major version of ruby-jwt")
          raise JWT::DecodeError, 'HMAC key expected to be a String' unless key.is_a?(String)

          if (hmac = resolve_algorithm(algorithm)) && key.bytesize <= hmac.key_bytes
            hmac.auth(padded_key_bytes(key, hmac.key_bytes), msg.encode('binary'))
          else
            Hmac.sign(algorithm, msg, key)
          end
        end

        def verify(algorithm, key, signing_input, signature)
          key ||= ''
          Deprecations.warning("The use of the algorithm #{algorithm} is deprecated and will be removed in the next major version of ruby-jwt")
          raise JWT::DecodeError, 'HMAC key expected to be a String' unless key.is_a?(String)

          if (hmac = resolve_algorithm(algorithm)) && key.bytesize <= hmac.key_bytes
            hmac.verify(padded_key_bytes(key, hmac.key_bytes), signature.encode('binary'), signing_input.encode('binary'))
          else
            Hmac.verify(algorithm, key, signing_input, signature)
          end
        rescue ::RbNaCl::BadAuthenticatorError, ::RbNaCl::LengthError
          false
        end

        def resolve_algorithm(algorithm)
          MAPPING.fetch(algorithm)
        end

        def padded_key_bytes(key, bytesize)
          key.bytes.fill(0, key.bytesize...bytesize).pack('C*')
        end
      end
    end
  end
end
