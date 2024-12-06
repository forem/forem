module Rpush
  module Client
    module ActiveModel
      class CertificatePrivateKeyValidator < ::ActiveModel::Validator
        def validate(record)
          if record.certificate.present?
            begin
              x509 = OpenSSL::X509::Certificate.new(record.certificate)
              pkey = OpenSSL::PKey::RSA.new(record.certificate, record.password)
              x509 && pkey
            rescue OpenSSL::OpenSSLError
              record.errors.add :certificate, 'value must contain a certificate and a private key.'
            end
          end
        end
      end
    end
  end
end
