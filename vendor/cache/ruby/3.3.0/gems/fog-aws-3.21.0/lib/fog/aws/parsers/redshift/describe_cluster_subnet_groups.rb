module Fog
  module Parsers
    module Redshift
      module AWS
        class DescribeClusterSubnetGroups < Fog::Parsers::Base
          # :marker - (String)
          # :cluster_subnet_groups - (Array<Hash>)
          #   :cluster_subnet_group_name - (String)
          #   :description - (String)
          #   :vpc_id - (String)
          #   :subnet_group_status - (String)
          #   :subnets - (Array<Hash>)
          #     :subnet_identifier - (String)
          #     :subnet_availability_zone - (Hash)
          #       :name - (String)
          #     :subnet_status - (String)

          def reset
            @response = { 'ClusterSubnetGroups' => [] }
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'ClusterSubnetGroups'
              @cluster_subnet_group = {'Subnets' => []}
            end
          end

          def end_element(name)
            super
            case name
            when 'Marker'
              @response[name] = value
            when 'ClusterSubnetGroup'
              @response['ClusterSubnetGroups'] << {name => @cluster_subnet_group}
              @cluster_subnet_group = {'Subnets' => []}
            when 'ClusterSubnetGroupName', 'Description', 'VpcId', 'SubnetGroupStatus'
              @cluster_subnet_group[name] = value
            when 'Subnet'
              @cluster_subnet_group['Subnets'] << {name => @subnet} if @subnet
              @subnet = {}
            when 'SubnetAvailabilityZone'
              @subnet['SubnetAvailabilityZone'] = {}
            when 'Name'
              @subnet['SubnetAvailabilityZone']['Name'] = value
            when 'SubnetIdentifier', 'SubnetStatus'
              @subnet[name] = value
            end
          end
        end
      end
    end
  end
end
