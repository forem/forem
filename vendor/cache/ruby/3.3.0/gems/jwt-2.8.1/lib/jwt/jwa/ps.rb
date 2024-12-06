# frozen_string_literal: true

module JWT
  module JWA
    module Ps
      # RSASSA-PSS signing algorithms

      module_function

      SUPPORTED = %w[PS256 PS384 PS512].freeze

      def sign(algorithm, msg, key)
        unless key.is_a?(::OpenSSL::PKey::RSA)
          raise EncodeError, "The given key is a #{key_class}. It has to be an OpenSSL::PKey::RSA instance."
        end

        translated_algorithm = algorithm.sub('PS', 'sha')

        key.sign_pss(translated_algorithm, msg, salt_length: :digest, mgf1_hash: translated_algorithm)
      end

      def verify(algorithm, public_key, signing_input, signature)
        translated_algorithm = algorithm.sub('PS', 'sha')
        public_key.verify_pss(translated_algorithm, signature, signing_input, salt_length: :auto, mgf1_hash: translated_algorithm)
      rescue OpenSSL::PKey::PKeyError
        raise JWT::VerificationError, 'Signature verification raised'
      end
    end
  end
end
