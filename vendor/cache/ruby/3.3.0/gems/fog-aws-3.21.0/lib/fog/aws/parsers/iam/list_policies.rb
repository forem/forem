module Fog
  module Parsers
    module AWS
      module IAM
        class ListPolicies < Fog::Parsers::Base
          def reset
            @response = { 'PolicyNames' => [] }
          end

          def end_element(name)
            case name
            when 'member'
              @response['PolicyNames'] << value
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
