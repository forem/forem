module Fog
  module Parsers
    module Redshift
      module AWS
        require 'fog/aws/parsers/redshift/cluster_security_group_parser'

        class RevokeClusterSecurityGroupIngress < ClusterSecurityGroupParser
          # :cluster_security_group

          def reset
            super
            @response = {}
          end

          def start_element(name, attrs = [])
            super
          end

          def end_element(name)
            super
            case name
            when 'ClusterSecurityGroup'
              @response['ClusterSecurityGroup'] = @cluster_security_group
            end
          end
        end
      end
    end
  end
end
