module Fog
  module Parsers
    module AWS
      module IAM
        class ListGroupsForUser < Fog::Parsers::Base
          def reset
            @group_for_user = {}
            @response = { 'GroupsForUser' => [] }
          end

          def end_element(name)
            case name
            when 'Path', 'GroupName', 'GroupId', 'Arn'
              @group_for_user[name] = value
            when 'member'
              @response['GroupsForUser'] << @group_for_user
              @group_for_user = {}
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
