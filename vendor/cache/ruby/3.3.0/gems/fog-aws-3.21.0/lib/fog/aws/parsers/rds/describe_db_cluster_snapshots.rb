module Fog
  module Parsers
    module AWS
      module RDS
        require 'fog/aws/parsers/rds/db_cluster_snapshot_parser'

        class DescribeDBClusterSnapshots < Fog::Parsers::AWS::RDS::DBClusterSnapshotParser
          def reset
            @response = {'DescribeDBClusterSnapshotsResult' => {'DBClusterSnapshots' => []}, 'ResponseMetadata' => {}}
            super
          end

          def start_element(name, attrs = [])
            super
          end

          def end_element(name)
            case name
            when 'DBClusterSnapshot'
              @response['DescribeDBClusterSnapshotsResult']['DBClusterSnapshots'] << @db_cluster_snapshot
              @db_cluster_snapshot = fresh_snapshot
            when 'Marker'
              @response['DescribeDBClusterSnapshotsResult']['Marker'] = value
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
