unless defined? OpenSSL
  begin
    require 'digest/md5'
  rescue LoadError
  end
end

class Net::SMTP
  class AuthCramMD5 < Net::SMTP::Authenticator
    auth_type :cram_md5

    def auth(user, secret)
      challenge = continue('AUTH CRAM-MD5')
      crammed = cram_md5_response(secret, challenge.unpack1('m'))
      finish(base64_encode("#{user} #{crammed}"))
    end

    IMASK = 0x36
    OMASK = 0x5c

    # CRAM-MD5: [RFC2195]
    def cram_md5_response(secret, challenge)
      tmp = digest_class::MD5.digest(cram_secret(secret, IMASK) + challenge)
      digest_class::MD5.hexdigest(cram_secret(secret, OMASK) + tmp)
    end

    CRAM_BUFSIZE = 64

    def cram_secret(secret, mask)
      secret = digest_class::MD5.digest(secret) if secret.size > CRAM_BUFSIZE
      buf = secret.ljust(CRAM_BUFSIZE, "\0")
      0.upto(buf.size - 1) do |i|
        buf[i] = (buf[i].ord ^ mask).chr
      end
      buf
    end

    def digest_class
      @digest_class ||= if defined?(OpenSSL::Digest)
                          OpenSSL::Digest
                        elsif defined?(::Digest)
                          ::Digest
                        else
                          raise '"openssl" or "digest" library is required'
                        end
    end
  end
end
