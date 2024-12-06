module Fog
  module Parsers
    module AWS
      module RDS
        require 'fog/aws/parsers/rds/db_cluster_snapshot_parser'

        class CreateDBClusterSnapshot < Fog::Parsers::AWS::RDS::DBClusterSnapshotParser
          def reset
            @response = { 'CreateDBClusterSnapshotResult' => {}, 'ResponseMetadata' => {} }
            super
          end

          def start_element(name, attrs = [])
            super
          end

          def end_element(name)
            case name

            when 'DBClusterSnapshot'
              @response['CreateDBClusterSnapshotResult']['DBClusterSnapshot'] = @db_cluster_snapshot
              @db_cluster_snapshot = fresh_snapshot
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
