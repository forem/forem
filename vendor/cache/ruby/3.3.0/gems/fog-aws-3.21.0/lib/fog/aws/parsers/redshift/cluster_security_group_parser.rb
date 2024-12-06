module Fog
  module Parsers
    module Redshift
      module AWS
        class ClusterSecurityGroupParser < Fog::Parsers::Base
          #   :cluster_security_group_name - (String)
          #   :description - (String)
          #   :ec_2_security_groups - (Array)
          #     :status - (String)
          #     :ec2_security_group_name - (String)
          #     :ec2_security_group_owner_id - (String)
          #   :ip_ranges - (Array)
          #     :status - (String)
          #     :cidrip - (String)

          def reset
            @cluster_security_group = fresh_cluster_security_group
          end

          def fresh_cluster_security_group
            {'EC2SecurityGroups' => [], 'IPRanges' => []}
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'EC2SecurityGroups', 'IPRanges'
              @list = {}
              @list_name = name
            end
          end

          def end_element(name)
            super
            case name
            when 'ClusterSecurityGroupName', 'Description'
              @cluster_security_group[name] = value
            when 'EC2SecurityGroupName', 'EC2SecurityGroupOwnerId', 'CIDRIP', 'Status'
              @list[name] = value
            when 'EC2SecurityGroup', 'IPRange'
              @cluster_security_group[@list_name] << {name => @list}
              @list = {}
            end
          end
        end
      end
    end
  end
end
