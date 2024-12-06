module Fog
  module Parsers
    module AWS
      module RDS
        require 'fog/aws/parsers/rds/snapshot_parser'

        class CopyDBSnapshot < Fog::Parsers::AWS::RDS::SnapshotParser
          def reset
            @response = { 'CopyDBSnapshotResult' => {}, 'ResponseMetadata' => {} }
            super
          end

          def start_element(name, attrs = [])
            super
          end

          def end_element(name)
            case name
            when 'DBSnapshot' then
              @response['CopyDBSnapshotResult']['DBSnapshot'] = @db_snapshot
              @db_snapshot = fresh_snapshot
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
