module Fog
  module Parsers
    module Redshift
      module AWS
        require 'fog/aws/parsers/redshift/cluster_parser'

        class Cluster < ClusterParser
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
            when 'Cluster'
              @response = {name => @cluster}
            end
          end
        end
      end
    end
  end
end
