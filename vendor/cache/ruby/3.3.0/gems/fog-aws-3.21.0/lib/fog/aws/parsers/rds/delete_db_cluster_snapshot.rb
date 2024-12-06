module Fog
  module Parsers
    module AWS
      module RDS
        require 'fog/aws/parsers/rds/db_cluster_snapshot_parser'

        class DeleteDBClusterSnapshot < Fog::Parsers::AWS::RDS::DBClusterSnapshotParser
          def reset
            @response = {'DeleteDBClusterSnapshotResult' => {}, 'ResponseMetadata' => {} }
            super
          end

          def start_element(name, attrs = [])
            super
          end

          def end_element(name)
            case name
            when 'RequestId'
              @response['ResponseMetadata'][name] = value
            when 'DBClusterSnapshot'
              @response['DeleteDBClusterSnapshotResult']['DBClusterSnapshot'] = @db_cluster_snapshot
              @db_cluster_snapshot = fresh_snapshot
            else
              super
            end
          end
        end
      end
    end
  end
end
