module Fog
  module Parsers
    module AWS
      module RDS
        class DBClusterSnapshotParser < Fog::Parsers::Base
          def reset
            @db_cluster_snapshot = fresh_snapshot
          end

          def fresh_snapshot
            {}
          end

          def start_element(name, attrs=[])
            super
          end

          def end_element(name)
            case name
            when 'Port', 'PercentProgress', 'AllocatedStorage'
              @db_cluster_snapshot[name] = value.to_i
            when 'SnapshotCreateTime', 'ClusterCreateTime'
              @db_cluster_snapshot[name] = Time.parse(value)
            else
              @db_cluster_snapshot[name] = value
            end
          end
        end
      end
    end
  end
end
