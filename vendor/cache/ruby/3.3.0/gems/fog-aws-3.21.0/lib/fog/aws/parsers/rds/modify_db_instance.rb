module Fog
  module Parsers
    module AWS
      module RDS
        require 'fog/aws/parsers/rds/db_parser'

        class ModifyDBInstance < Fog::Parsers::AWS::RDS::DbParser
          def reset
            @response = { 'ModifyDBInstanceResult' => {}, 'ResponseMetadata' => {} }
            super
          end

          def start_element(name, attrs = [])
            super
          end

          def end_element(name)
            case name
            when 'DBInstance'
              @response['ModifyDBInstanceResult']['DBInstance'] = @db_instance
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
