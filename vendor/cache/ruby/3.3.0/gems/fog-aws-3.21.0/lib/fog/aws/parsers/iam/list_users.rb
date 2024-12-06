module Fog
  module Parsers
    module AWS
      module IAM
        class ListUsers < Fog::Parsers::Base
          def reset
            @user = {}
            @response = { 'Users' => [] }
          end

          def end_element(name)
            case name
            when 'Arn', 'UserId', 'UserName', 'Path'
              @user[name] = value
            when 'CreateDate'
              @user[name] = Time.parse(value)
            when 'member'
              @response['Users'] << @user
              @user = {}
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
