module Fog
  module Parsers
    module Redshift
      module AWS
        class DescribeOrderableClusterOptions < Fog::Parsers::Base
          # :marker - (String)
          # :orderable_cluster_options - (Array)
          #   :cluster_version - (String)
          #   :cluster_type - (String)
          #   :node_type - (String)
          #   :availability_zones - (Array)
          #     :name - (String)

          def reset
            @response = { 'OrderableClusterOptions' => [] }
          end

          def fresh_orderable_cluster_option
           {'AvailabilityZones' => []}
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'OrderableClusterOptions'
              @orderable_cluster_option = fresh_orderable_cluster_option
            when 'AvailabilityZones'
              @availability_zone = {}
            end
          end

          def end_element(name)
            super
            case name
            when 'Marker'
              @response[name] = value
            when 'ClusterVersion', 'ClusterType', 'NodeType'
              @orderable_cluster_option[name] = value
            when 'Name'
              @availability_zone[name] = value
            when 'AvailabilityZone'
              @orderable_cluster_option['AvailabilityZones'] << {name => @availability_zone}
              @availability_zone = {}
            when 'OrderableClusterOption'
              @response['OrderableClusterOptions'] << {name => @orderable_cluster_option}
              @orderable_cluster_option = fresh_orderable_cluster_option
            end
          end
        end
      end
    end
  end
end
