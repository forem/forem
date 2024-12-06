module Fog
  module Parsers
    module AWS
      module RDS
        require 'fog/aws/parsers/rds/db_parser'

        class RestoreDBInstanceFromDBSnapshot < Fog::Parsers::AWS::RDS::DbParser
          def reset
            @response = { 'RestoreDBInstanceFromDBSnapshotResult' => {}, 'ResponseMetadata' => {} }
            super
          end

          def start_element(name, attrs = [])
            super
          end

          def end_element(name)
            case name
            when 'DBInstance'
              @response['RestoreDBInstanceFromDBSnapshotResult']['DBInstance'] = @db_instance
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
