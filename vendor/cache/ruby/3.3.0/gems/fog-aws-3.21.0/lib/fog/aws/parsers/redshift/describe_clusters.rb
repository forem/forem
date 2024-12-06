module Fog
  module Parsers
    module Redshift
      module AWS
        require 'fog/aws/parsers/redshift/cluster_parser'

        class DescribeClusters < ClusterParser
          def reset
            super
            @response = {"ClusterSet" => []}
          end

          def start_element(name, attrs = [])
            super
          end

          def end_element(name)
            super
            case name
            when 'Cluster'
              @response["ClusterSet"] << {name => @cluster}
              @cluster = fresh_cluster
            end
          end
        end
      end
    end
  end
end
