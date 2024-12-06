module Fog
  module Parsers
    module AWS
      module RDS
        require 'fog/aws/parsers/rds/snapshot_parser'

        class DeleteDBSnapshot < Fog::Parsers::AWS::RDS::SnapshotParser
          def reset
            @response = { 'DeleteDBSnapshotResult' => {}, 'ResponseMetadata' => {} }
            super
          end

          def start_element(name, attrs = [])
            super
          end

          def end_element(name)
            case name
            when 'RequestId'
              @response['ResponseMetadata'][name] = value
            when 'DBSnapshot'
              @response['DeleteDBSnapshotResult']['DBSnapshot'] = @db_snapshot
              @db_snapshot = fresh_snapshot
            else
              super
            end
          end
        end
      end
    end
  end
end
