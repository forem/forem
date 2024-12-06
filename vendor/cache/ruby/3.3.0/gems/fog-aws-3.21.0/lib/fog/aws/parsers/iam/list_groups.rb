module Fog
  module Parsers
    module AWS
      module IAM
        class ListGroups < Fog::Parsers::Base
          def reset
            @group = {}
            @response = { 'Groups' => [] }
          end

          def end_element(name)
            case name
            when 'Arn', 'GroupId', 'GroupName', 'Path'
              @group[name] = value
            when 'member'
              @response['Groups'] << @group
              @group = {}
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
