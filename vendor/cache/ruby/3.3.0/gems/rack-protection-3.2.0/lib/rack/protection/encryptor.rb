# frozen_string_literal: true

require 'openssl'

module Rack
  module Protection
    module Encryptor
      CIPHER     = 'aes-256-gcm'
      DELIMITER  = '--'

      def self.base64_encode(str)
        [str].pack('m0')
      end

      def self.base64_decode(str)
        str.unpack1('m0')
      end

      def self.encrypt_message(data, secret, auth_data = '')
        raise ArgumentError, 'data cannot be nil' if data.nil?

        cipher = OpenSSL::Cipher.new(CIPHER)
        cipher.encrypt
        cipher.key = secret[0, cipher.key_len]

        # Rely on OpenSSL for the initialization vector
        iv = cipher.random_iv

        # This must be set to properly use AES GCM for the OpenSSL module
        cipher.auth_data = auth_data

        cipher_text = cipher.update(data)
        cipher_text << cipher.final

        "#{base64_encode cipher_text}#{DELIMITER}#{base64_encode iv}#{DELIMITER}#{base64_encode cipher.auth_tag}"
      end

      def self.decrypt_message(data, secret)
        return unless data

        cipher = OpenSSL::Cipher.new(CIPHER)
        cipher_text, iv, auth_tag = data.split(DELIMITER, 3).map! { |v| base64_decode(v) }

        # This check is from ActiveSupport::MessageEncryptor
        # see: https://github.com/ruby/openssl/issues/63
        return if auth_tag.nil? || auth_tag.bytes.length != 16

        cipher.decrypt
        cipher.key = secret[0, cipher.key_len]
        cipher.iv  = iv
        cipher.auth_tag = auth_tag
        cipher.auth_data = ''

        decrypted_data = cipher.update(cipher_text)
        decrypted_data << cipher.final
        decrypted_data
      rescue OpenSSL::Cipher::CipherError, TypeError, ArgumentError
        nil
      end
    end
  end
end
