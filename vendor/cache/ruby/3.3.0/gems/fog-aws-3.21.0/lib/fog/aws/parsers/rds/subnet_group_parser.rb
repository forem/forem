module Fog
  module Parsers
    module AWS
      module RDS
        class SubnetGroupParser < Fog::Parsers::Base
          def reset
            @db_subnet_group = fresh_subnet_group
          end

          def start_element(name, attrs = [])
            super
          end

          def end_element(name)
            case name
            when 'VpcId' then @db_subnet_group['VpcId'] = value
            when 'SubnetGroupStatus' then @db_subnet_group['SubnetGroupStatus'] = value
            when 'DBSubnetGroupDescription' then @db_subnet_group['DBSubnetGroupDescription'] = value
            when 'DBSubnetGroupName' then @db_subnet_group['DBSubnetGroupName'] = value
            when 'SubnetIdentifier' then @db_subnet_group['Subnets'] << value
            when 'Marker'
              @response['DescribeDBSubnetGroupsResult']['Marker'] = value
            when 'RequestId'
              @response['ResponseMetadata'][name] = value
            end
          end

          def fresh_subnet_group
            {'Subnets' => []}
          end
        end
      end
    end
  end
end
