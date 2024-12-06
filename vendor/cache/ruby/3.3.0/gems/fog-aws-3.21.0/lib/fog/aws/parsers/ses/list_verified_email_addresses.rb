module Fog
  module Parsers
    module AWS
      module SES
        class ListVerifiedEmailAddresses < Fog::Parsers::Base
          def reset
            @response = { 'VerifiedEmailAddresses' => [], 'ResponseMetadata' => {} }
          end

          def end_element(name)
            case name
            when 'member'
              @response['VerifiedEmailAddresses'] << value
            when 'RequestId'
              @response['ResponseMetadata'][name] = value
            end
          end
        end
      end
    end
  end
end
