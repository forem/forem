require 'openssl'

module OmniAuth
  module Facebook
    class SignedRequest
      class UnknownSignatureAlgorithmError < NotImplementedError; end
      SUPPORTED_ALGORITHM = 'HMAC-SHA256'

      attr_reader :value, :secret

      def self.parse(value, secret)
        new(value, secret).payload
      end

      def initialize(value, secret)
        @value = value
        @secret = secret
      end

      def payload
        @payload ||= parse_signed_request
      end

      private

      def parse_signed_request
        signature, encoded_payload = value.split('.')
        return if signature.nil?

        decoded_hex_signature = base64_decode_url(signature)
        decoded_payload = MultiJson.decode(base64_decode_url(encoded_payload))

        unless decoded_payload['algorithm'] == SUPPORTED_ALGORITHM
          raise UnknownSignatureAlgorithmError, "unknown algorithm: #{decoded_payload['algorithm']}"
        end

        if valid_signature?(decoded_hex_signature, encoded_payload)
          decoded_payload
        end
      end

      def valid_signature?(signature, payload, algorithm = OpenSSL::Digest::SHA256.new)
        OpenSSL::HMAC.digest(algorithm, secret, payload) == signature
      end

      def base64_decode_url(value)
        value += '=' * (4 - value.size.modulo(4))
        Base64.decode64(value.tr('-_', '+/'))
      end
    end
  end
end
