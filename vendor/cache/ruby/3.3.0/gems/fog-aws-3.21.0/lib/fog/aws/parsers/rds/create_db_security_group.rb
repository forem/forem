module Fog
  module Parsers
    module AWS
      module RDS
        require 'fog/aws/parsers/rds/security_group_parser'

        class CreateDBSecurityGroup < Fog::Parsers::AWS::RDS::SecurityGroupParser
          def reset
            @response = { 'CreateDBSecurityGroupResult' => {}, 'ResponseMetadata' => {} }
            super
          end

          def start_element(name, attrs = [])
            super
          end

          def end_element(name)
            case name
            when 'DBSecurityGroup' then
              @response['CreateDBSecurityGroupResult']['DBSecurityGroup'] = @security_group
              @security_group = fresh_security_group
            when 'RequestId'
              @response['ResponseMetadata'][name] = value
            else
              super
            end
          end
        end
      end
    end
  end
end
