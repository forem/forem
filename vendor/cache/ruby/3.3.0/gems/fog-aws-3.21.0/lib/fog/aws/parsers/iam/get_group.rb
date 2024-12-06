module Fog
  module Parsers
    module AWS
      module IAM
        class GetGroup < Fog::Parsers::Base
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/index.html?API_GetGroup.html

          def reset
            @user = {}
            @response = { 'Group' => {}, 'Users' => [] }
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'Group'
              @in_group = true
            when 'Users'
              @in_users = true
            end
          end

          def end_element(name)
            case name
            when 'Arn', 'Path'
              if @in_group
                @response['Group'][name] = value
              elsif @in_users
                @user[name] = value
              end
            when 'Group'
              @in_group = false
            when 'GroupName', 'GroupId'
              @response['Group'][name] = value
            when 'Users'
              @in_users = false
            when 'UserId', 'UserName'
              @user[name] = value
            when 'member'
              @response['Users'] << @user
              @user = {}
            when 'IsTruncated'
              response[name] = (value == 'true')
            when 'Marker', 'RequestId'
              @response[name] = value
            end
          end
        end
      end
    end
  end
end
