module Fog
  module Parsers
    module Redshift
      module AWS
        require 'fog/aws/parsers/redshift/cluster_snapshot_parser'

        class ClusterSnapshot < ClusterSnapshotParser
          # :parameter_group_name - (String)
          # :parameter_group_status - (String)

          def reset
            super
            @response = {}
          end

          def start_element(name, attrs = [])
            super
          end

          def end_element(name)
            super
            case name
            when 'Snapshot'
              @response = @snapshot
            end
          end
        end
      end
    end
  end
end
