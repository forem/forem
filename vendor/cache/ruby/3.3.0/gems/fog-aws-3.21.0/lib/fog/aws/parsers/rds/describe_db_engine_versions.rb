module Fog
  module Parsers
    module AWS
      module RDS
        require 'fog/aws/parsers/rds/db_engine_version_parser'

        class DescribeDBEngineVersions < Fog::Parsers::AWS::RDS::DBEngineVersionParser
          def reset
            @response = { 'DescribeDBEngineVersionsResult' => {'DBEngineVersions' => []}, 'ResponseMetadata' => {} }
            super
          end

          def start_element(name, attrs = [])
            super
          end

          def end_element(name)
            case name
            when 'DBEngineVersion' then
              @response['DescribeDBEngineVersionsResult']['DBEngineVersions'] << @db_engine_version
              @db_engine_version = fresh_engine_version
            when 'Marker'
              @response['DescribeDBEngineVersionsResult']['Marker'] = @value
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
