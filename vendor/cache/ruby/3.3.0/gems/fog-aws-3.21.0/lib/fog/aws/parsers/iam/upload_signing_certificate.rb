module Fog
  module Parsers
    module AWS
      module IAM
        class UploadSigningCertificate < Fog::Parsers::Base
          def reset
            @response = { 'Certificate' => {} }
          end

          def end_element(name)
            case name
            when 'CertificateId', 'UserName', 'CertificateBody', 'Status'
              @response['Certificate'][name] = value
            when 'RequestId'
              @response[name] = value
            end
          end
        end
      end
    end
  end
end
