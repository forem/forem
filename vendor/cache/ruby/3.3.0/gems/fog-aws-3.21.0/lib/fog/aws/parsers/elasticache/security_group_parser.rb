module Fog
  module Parsers
    module AWS
      module Elasticache
        require 'fog/aws/parsers/elasticache/base'

        class SecurityGroupParser < Fog::Parsers::Base
          def reset
            super
            reset_security_group
          end

          def reset_security_group
            @security_group = {'EC2SecurityGroups' => []}
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'EC2SecurityGroup'; then @ec2_group = {}
            end
          end

          def end_element(name)
            case name
            when 'Description', 'CacheSecurityGroupName', 'OwnerId'
              @security_group[name] = value
            when 'EC2SecurityGroup'
              @security_group["#{name}s"] << @ec2_group unless @ec2_group.empty?
            when 'EC2SecurityGroupName', 'EC2SecurityGroupOwnerId', 'Status'
              @ec2_group[name] = value
            end
          end
        end
      end
    end
  end
end
