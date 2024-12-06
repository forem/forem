# frozen_string_literal: true

module JWT
  module JWA
    module Hmac
      module_function

      MAPPING = {
        'HS256' => OpenSSL::Digest::SHA256,
        'HS384' => OpenSSL::Digest::SHA384,
        'HS512' => OpenSSL::Digest::SHA512
      }.freeze

      SUPPORTED = MAPPING.keys

      def sign(algorithm, msg, key)
        key ||= ''

        raise JWT::DecodeError, 'HMAC key expected to be a String' unless key.is_a?(String)

        OpenSSL::HMAC.digest(MAPPING[algorithm].new, key, msg)
      rescue OpenSSL::HMACError => e
        if key == '' && e.message == 'EVP_PKEY_new_mac_key: malloc failure'
          raise JWT::DecodeError, 'OpenSSL 3.0 does not support nil or empty hmac_secret'
        end

        raise e
      end

      def verify(algorithm, key, signing_input, signature)
        SecurityUtils.secure_compare(signature, sign(algorithm, signing_input, key))
      end

      # Copy of https://github.com/rails/rails/blob/v7.0.3.1/activesupport/lib/active_support/security_utils.rb
      # rubocop:disable Naming/MethodParameterName, Style/StringLiterals, Style/NumericPredicate
      module SecurityUtils
        # Constant time string comparison, for fixed length strings.
        #
        # The values compared should be of fixed length, such as strings
        # that have already been processed by HMAC. Raises in case of length mismatch.

        if defined?(OpenSSL.fixed_length_secure_compare)
          def fixed_length_secure_compare(a, b)
            OpenSSL.fixed_length_secure_compare(a, b)
          end
        else
          # :nocov:
          def fixed_length_secure_compare(a, b)
            raise ArgumentError, "string length mismatch." unless a.bytesize == b.bytesize

            l = a.unpack "C#{a.bytesize}"

            res = 0
            b.each_byte { |byte| res |= byte ^ l.shift }
            res == 0
          end
          # :nocov:
        end
        module_function :fixed_length_secure_compare

        # Secure string comparison for strings of variable length.
        #
        # While a timing attack would not be able to discern the content of
        # a secret compared via secure_compare, it is possible to determine
        # the secret length. This should be considered when using secure_compare
        # to compare weak, short secrets to user input.
        def secure_compare(a, b)
          a.bytesize == b.bytesize && fixed_length_secure_compare(a, b)
        end
        module_function :secure_compare
      end
      # rubocop:enable Naming/MethodParameterName, Style/StringLiterals, Style/NumericPredicate
    end
  end
end
