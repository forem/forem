module Fog
  module Parsers
    module AWS
      module IAM
        class ListSigningCertificates < Fog::Parsers::Base
          def reset
            @signing_certificate = {}
            @response = { 'SigningCertificates' => [] }
          end

          def end_element(name)
            case name
            when 'UserName', 'CertificateId', 'CertificateBody', 'Status'
              @signing_certificate[name] = value
            when 'member'
              @response['SigningCertificates'] << @signing_certificate
              @signing_certificate = {}
            when 'IsTruncated'
              response[name] = (value == 'true')
            when 'Marker', 'RequestId'
              response[name] = value
            end
          end
        end
      end
    end
  end
end
