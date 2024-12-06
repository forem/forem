module Fog
  module Parsers
    module AWS
      module RDS
        require 'fog/aws/parsers/rds/db_parser'

        class DeleteDBInstance < Fog::Parsers::AWS::RDS::DbParser
          def reset
            @response = { 'DeleteDBInstanceResult' => {}, 'ResponseMetadata' => {} }
            super
          end

          def start_element(name, attrs = [])
            super
          end

          def end_element(name)
            case name

            when 'DBInstance'
              @response['DeleteDBInstanceResult']['DBInstance'] = @db_instance
              @db_instance = fresh_instance
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
