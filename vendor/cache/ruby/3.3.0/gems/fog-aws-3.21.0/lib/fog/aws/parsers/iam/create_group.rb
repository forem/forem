module Fog
  module Parsers
    module AWS
      module IAM
        class CreateGroup < Fog::Parsers::Base
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
