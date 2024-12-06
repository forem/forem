module Fog
  module Parsers
    module Redshift
      module AWS
        class DescribeClusterVersions < Fog::Parsers::Base
          # :marker - (String)
          # :cluster_versions - (Array<Hash>)
          #   :cluster_version - (String)
          #   :cluster_parameter_group_family - (String)
          #   :description - (String)

          def reset
            @response = { 'ClusterVersions' => [] }
            @cluster_version_depth = 0
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'ClusterVersions'
              @cluster_version = {}
            when 'ClusterVersion'
              # Sadly, there are two nodes of different type named cluster_version
              # that are nested, so we keep track of which one we're in
              @cluster_version_depth += 1
            end
          end

          def end_element(name)
            super
            case name
            when 'Marker'
              @response[name] = value
            when 'ClusterVersion'
              @cluster_version_depth -= 1
              if @cluster_version_depth == 0
                @response['ClusterVersions'] << {name => @cluster_version}
                @cluster_version = {}
              else
                @cluster_version[name] = value
              end
            when 'ClusterParameterGroupFamily', 'Description'
              @cluster_version[name] = value
            end
          end
        end
      end
    end
  end
end
