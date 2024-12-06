module Fog
  module Parsers
    module Redshift
      module AWS
        require 'fog/aws/parsers/redshift/cluster_snapshot_parser'

        class DescribeClusterSnapshots < ClusterSnapshotParser
          # :marker - (String)
          # :snapshots - (Array)

          def reset
            @response = { 'Snapshots' => [] }
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'Snapshots'
              @snapshot = fresh_snapshot
            end
          end

          def end_element(name)
            super
            case name
            when 'Marker'
              @response[name] = value
            when 'Snapshot'
              @response['Snapshots'] << @snapshot
              @snapshot = fresh_snapshot
            end
          end
        end
      end
    end
  end
end
