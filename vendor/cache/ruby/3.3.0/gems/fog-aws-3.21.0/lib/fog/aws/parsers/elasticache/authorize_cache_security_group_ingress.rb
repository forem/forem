module Fog
  module Parsers
    module AWS
      module Elasticache
        require 'fog/aws/parsers/elasticache/security_group_parser'

        class AuthorizeCacheSecurityGroupIngress < Fog::Parsers::AWS::Elasticache::SecurityGroupParser
          def end_element(name)
            case name
            when 'CacheSecurityGroup' then
              @response['CacheSecurityGroup'] = @security_group
              reset_security_group
            else
              super
            end
          end
        end
      end
    end
  end
end
