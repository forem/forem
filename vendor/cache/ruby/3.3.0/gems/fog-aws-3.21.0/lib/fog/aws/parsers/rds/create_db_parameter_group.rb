module Fog
  module Parsers
    module AWS
      module RDS
        class CreateDbParameterGroup < Fog::Parsers::Base
          def reset
            @response = { 'CreateDBParameterGroupResult' => {}, 'ResponseMetadata' => {} }
            @db_parameter_group = {}
          end

          def start_element(name, attrs = [])
            super
          end

          def end_element(name)
            case name
            when 'DBParameterGroupFamily'
              @db_parameter_group['DBParameterGroupFamily'] = value
            when 'Description'
              @db_parameter_group['Description'] = value
            when 'DBParameterGroupName'
              @db_parameter_group['DBParameterGroupName'] = value
            when 'DBParameterGroup'
              @response['CreateDBParameterGroupResult']['DBParameterGroup']= @db_parameter_group
            when 'RequestId'
              @response['ResponseMetadata'][name] = value
            end
          end
        end
      end
    end
  end
end
