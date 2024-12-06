module Fog
  module Parsers
    module AWS
      module RDS
        require 'fog/aws/parsers/rds/subnet_group_parser'

        class DescribeDBSubnetGroups < Fog::Parsers::AWS::RDS::SubnetGroupParser
          def reset
            @response = { 'DescribeDBSubnetGroupsResult' => {'DBSubnetGroups' => []}, 'ResponseMetadata' => {} }
            super
          end

          def start_element(name, attrs = [])
            super
          end

          def end_element(name)
            case name
            when 'DBSubnetGroup'
              @response['DescribeDBSubnetGroupsResult']['DBSubnetGroups'] << @db_subnet_group
              @db_subnet_group = fresh_subnet_group
            when 'Marker'
              @response['DescribeDBSubnetGroupsResult']['Marker'] = value
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
