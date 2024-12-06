module Fog
  module Parsers
    module AWS
      module RDS
        require 'fog/aws/parsers/rds/db_parameter_parser'

        class DescribeEngineDefaultParameters < Fog::Parsers::AWS::RDS::DBParameterParser
          def reset
            @response = {'DescribeEngineDefaultParametersResult' => {'Parameters' => []}, 'ResponseMetadata' => {}}
            super
          end

          def start_element(name, attrs = [])
            super
          end

          def end_element(name)
            case name
            when 'Parameter'
              @response['DescribeEngineDefaultParametersResult']['Parameters'] << @db_parameter
              @db_parameter = new_db_parameter
            when 'Marker'
              @response['DescribeEngineDefaultParametersResult']['Marker'] = @value
            when 'RequestId'
              @response['ResponseMetadata'][name] = @value
            else
              super
            end
          end
        end
      end
    end
  end
end
