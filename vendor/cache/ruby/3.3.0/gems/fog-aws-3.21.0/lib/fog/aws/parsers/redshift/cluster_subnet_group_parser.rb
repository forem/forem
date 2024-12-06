module Fog
  module Parsers
    module Redshift
      module AWS
        class ClusterSubnetGroupParser < Fog::Parsers::Base
          # :cluster_subnet_group_name - (String)
          # :description - (String)
          # :vpc_id - (String)
          # :subnet_group_status - (String)
          # :subnets - (Array)
          #   :subnet_identifier - (String)
          #   :subnet_availability_zone - (Hash)
          #     :name - (String)
          #   :subnet_status - (String)

          def reset
            @response = { 'Subnets' => [] }
          end

          def fresh_subnet
            {'SubnetAvailabilityZone'=>{}}
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'Subnets'
              @subnet = fresh_subnet
            end
          end

          def end_element(name)
            super
            case name
            when 'ClusterSubnetGroupName', 'Desciption', 'VpcId', 'SubnetGroupStatus'
              @response[name] = value
            when 'SubnetIdentifier', 'SubnetStatus'
              @subnet[name] = value
            when 'Name'
              @subnet['SubnetAvailabilityZone'][name] = value
            when 'Subnet'
              @response['Subnets'] << {name => @subnet}
              @subnet = fresh_subnet
            end
          end
        end
      end
    end
  end
end
