module Fog
  module Parsers
    module AWS
      module IAM
        require 'fog/aws/parsers/iam/role_parser'
        class ListRoles < Fog::Parsers::AWS::IAM::RoleParser
          def reset
            super
            @response = { 'Roles' => [] }
          end

          def finished_role(role)
            @response['Roles'] << role
          end

          def end_element(name)
            case name
            when 'RequestId', 'Marker'
              @response[name] = value
            when 'IsTruncated'
              @response[name] = (value == 'true')
            end
            super
          end
        end
      end
    end
  end
end
