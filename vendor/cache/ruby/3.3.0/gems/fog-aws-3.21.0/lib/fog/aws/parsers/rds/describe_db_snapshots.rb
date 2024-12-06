module Fog
  module Parsers
    module AWS
      module RDS
        require 'fog/aws/parsers/rds/snapshot_parser'

        class DescribeDBSnapshots < Fog::Parsers::AWS::RDS::SnapshotParser
          def reset
            @response = { 'DescribeDBSnapshotsResult' => {'DBSnapshots' => []}, 'ResponseMetadata' => {} }
            super
          end

          def start_element(name, attrs = [])
            super
          end

          def end_element(name)
            case name
            when 'DBSnapshot' then
              @response['DescribeDBSnapshotsResult']['DBSnapshots'] << @db_snapshot
              @db_snapshot = fresh_snapshot
            when 'Marker'
              @response['DescribeDBSnapshotsResult']['Marker'] = value
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
