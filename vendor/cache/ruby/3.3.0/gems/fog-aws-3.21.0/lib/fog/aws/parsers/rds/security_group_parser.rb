module Fog
  module Parsers
    module AWS
      module RDS
        class SecurityGroupParser < Fog::Parsers::Base
          def reset
            @security_group = fresh_security_group
          end

          def fresh_security_group
            {'EC2SecurityGroups' => [], 'IPRanges' => []}
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'EC2SecurityGroup', 'IPRange'; then @ingress = {}
            end
          end

          def end_element(name)
            case name
            when 'DBSecurityGroupDescription' then @security_group['DBSecurityGroupDescription'] = value
            when 'DBSecurityGroupName' then @security_group['DBSecurityGroupName'] = value
            when 'OwnerId' then @security_group['OwnerId'] = value
            when 'EC2SecurityGroup', 'IPRange'
              @security_group["#{name}s"] << @ingress unless @ingress.empty?
            when 'EC2SecurityGroupName', 'EC2SecurityGroupOwnerId', 'CIDRIP', 'Status'
              @ingress[name] = value
            end
          end
        end
      end
    end
  end
end
