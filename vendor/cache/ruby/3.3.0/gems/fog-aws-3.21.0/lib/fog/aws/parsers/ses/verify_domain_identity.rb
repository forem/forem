module Fog
  module Parsers
    module AWS
      module SES
        class VerifyDomainIdentity < Fog::Parsers::Base
          def reset
            @response = { 'ResponseMetadata' => {} }
          end

          def end_element(name)
            case name
            when 'VerificationToken'
              @response[name] = value
            when 'RequestId'
              @response['ResponseMetadata'][name] = value
            end
          end
        end
      end
    end
  end
end
