module Fog
  module Parsers
    module AWS
      module IAM
        class ListServerCertificates < Fog::Parsers::Base
          def reset
            @response = { 'Certificates' => [] }
            reset_certificate
          end

          def reset_certificate
            @certificate = {}
          end

          def end_element(name)
            case name
            when 'Arn', 'Path', 'ServerCertificateId', 'ServerCertificateName'
              @certificate[name] = value
            when 'UploadDate'
              @certificate[name] = Time.parse(value)
            when 'member'
              @response['Certificates'] << @certificate
              reset_certificate
            when 'IsTrunctated'
              @response[name] = !!value
            when 'Marker'
              @response[name] = value
            end
          end
        end
      end
    end
  end
end
