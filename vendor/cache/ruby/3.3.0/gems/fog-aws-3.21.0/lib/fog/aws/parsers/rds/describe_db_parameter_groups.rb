module Fog
  module Parsers
    module AWS
      module RDS
        class DescribeDBParameterGroups < Fog::Parsers::Base
          def reset
            @response = { 'DescribeDBParameterGroupsResult' => {'DBParameterGroups' => []}, 'ResponseMetadata' => {} }
            @db_parameter_group = {}
          end

          def start_element(name, attrs = [])
            super
          end

          def end_element(name)
            case name
            when 'DBParameterGroupFamily' then @db_parameter_group['DBParameterGroupFamily'] = value
            when 'Description' then @db_parameter_group['Description'] = value
            when 'DBParameterGroupName' then @db_parameter_group['DBParameterGroupName'] = value
            when 'DBParameterGroup' then
              @response['DescribeDBParameterGroupsResult']['DBParameterGroups'] << @db_parameter_group
              @db_parameter_group = {}
            when 'Marker'
              @response['DescribeDBParameterGroupsResult']['Marker'] = value
            when 'RequestId'
              @response['ResponseMetadata'][name] = value
            end
          end
        end
      end
    end
  end
end
