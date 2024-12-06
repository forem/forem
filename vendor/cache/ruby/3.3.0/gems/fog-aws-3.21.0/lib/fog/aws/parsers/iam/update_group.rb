module Fog
  module Parsers
    module AWS
      module IAM
        class UpdateGroup < Fog::Parsers::Base
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/index.html?API_UpdateGroup.html
          def reset
            @response = { 'Group' => {} }
          end

          def end_element(name)
            case name
            when 'Arn', 'GroupId', 'GroupName', 'Path'
              @response['Group'][name] = value
            when 'RequestId'
              @response[name] = value
            end
          end
        end
      end
    end
  end
end
