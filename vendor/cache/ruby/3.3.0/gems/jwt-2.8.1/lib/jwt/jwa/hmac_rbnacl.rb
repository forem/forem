# frozen_string_literal: true

module JWT
  module Algos
    module HmacRbNaCl
      MAPPING   = { 'HS512256' => ::RbNaCl::HMAC::SHA512256 }.freeze
      SUPPORTED = MAPPING.keys
      class << self
        def sign(algorithm, msg, key)
          Deprecations.warning("The use of the algorithm #{algorithm} is deprecated and will be removed in the next major version of ruby-jwt")
          if (hmac = resolve_algorithm(algorithm))
            hmac.auth(key_for_rbnacl(hmac, key).encode('binary'), msg.encode('binary'))
          else
            Hmac.sign(algorithm, msg, key)
          end
        end

        def verify(algorithm, key, signing_input, signature)
          Deprecations.warning("The use of the algorithm #{algorithm} is deprecated and will be removed in the next major version of ruby-jwt")
          if (hmac = resolve_algorithm(algorithm))
            hmac.verify(key_for_rbnacl(hmac, key).encode('binary'), signature.encode('binary'), signing_input.encode('binary'))
          else
            Hmac.verify(algorithm, key, signing_input, signature)
          end
        rescue ::RbNaCl::BadAuthenticatorError, ::RbNaCl::LengthError
          false
        end

        private

        def key_for_rbnacl(hmac, key)
          key ||= ''
          raise JWT::DecodeError, 'HMAC key expected to be a String' unless key.is_a?(String)

          return padded_empty_key(hmac.key_bytes) if key == ''

          key
        end

        def resolve_algorithm(algorithm)
          MAPPING.fetch(algorithm)
        end

        def padded_empty_key(length)
          Array.new(length, 0x0).pack('C*').encode('binary')
        end
      end
    end
  end
end
