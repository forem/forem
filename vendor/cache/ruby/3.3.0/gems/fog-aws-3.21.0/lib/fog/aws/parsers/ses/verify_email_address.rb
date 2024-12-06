module Fog
  module Parsers
    module AWS
      module SES
        class VerifyEmailAddress < Fog::Parsers::Base
          def reset
            @response = { 'ResponseMetadata' => {} }
          end

          def end_element(name)
            case name
            when 'RequestId'
              @response['ResponseMetadata'][name] = value
            end
          end
        end
      end
    end
  end
end
