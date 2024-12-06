module Fog
  module Parsers
    module Redshift
      module AWS
        require 'fog/aws/parsers/redshift/cluster_security_group_parser'

        class DescribeClusterSecurityGroups < ClusterSecurityGroupParser
          # :marker - (String)
          # :cluster_security_groups - (Array)

          def reset
            @response = { 'ClusterSecurityGroups' => [] }
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'ClusterSecurityGroups'
              @cluster_security_group = fresh_cluster_security_group
            end
          end

          def end_element(name)
            super
            case name
            when 'Marker'
              @response[name] = value
            when 'ClusterSecurityGroup'
              @response['ClusterSecurityGroups'] << { name => @cluster_security_group }
              @cluster_security_group = fresh_cluster_security_group
            end
          end
        end
      end
    end
  end
end
