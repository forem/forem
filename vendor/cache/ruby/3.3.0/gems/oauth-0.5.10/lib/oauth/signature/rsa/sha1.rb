require "oauth/signature/base"

module OAuth::Signature::RSA
  class SHA1 < OAuth::Signature::Base
    implements "rsa-sha1"

    def ==(cmp_signature)
      public_key.verify(OpenSSL::Digest::SHA1.new, Base64.decode64(cmp_signature.is_a?(Array) ? cmp_signature.first : cmp_signature), signature_base_string)
    end

    def public_key
      if consumer_secret.is_a?(String)
        decode_public_key
      elsif consumer_secret.is_a?(OpenSSL::X509::Certificate)
        consumer_secret.public_key
      else
        consumer_secret
      end
    end

    def body_hash
      Base64.encode64(OpenSSL::Digest::SHA1.digest(request.body || "")).chomp.delete("\n")
    end

    private

    def decode_public_key
      case consumer_secret
      when /-----BEGIN CERTIFICATE-----/
        OpenSSL::X509::Certificate.new(consumer_secret).public_key
      else
        OpenSSL::PKey::RSA.new(consumer_secret)
      end
    end

    def digest
      private_key = OpenSSL::PKey::RSA.new(
        if options[:private_key_file]
          IO.read(options[:private_key_file])
        elsif options[:private_key]
          options[:private_key]
        else
          consumer_secret
        end
      )

      private_key.sign(OpenSSL::Digest::SHA1.new, signature_base_string)
    end
  end
end
