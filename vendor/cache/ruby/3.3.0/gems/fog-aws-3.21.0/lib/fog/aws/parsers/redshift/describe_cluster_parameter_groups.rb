module Fog
  module Parsers
    module Redshift
      module AWS
        class DescribeClusterParameterGroups < Fog::Parsers::Base
          # :marker - (String)
          # :parameter_groups - (Array)
          #   :parameter_group_name - (String)
          #   :parameter_group_family - (String)
          #   :description - (String)

          def reset
            @response = { 'ParameterGroups' => [] }
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'ParameterGroups'
              @parameter_group = {}
            end
          end

          def end_element(name)
            super
            case name
            when 'Marker'
              @response[name] = value
            when 'ParameterGroupName', 'ParameterGroupFamily', 'Description'
              @parameter_group[name] = value
            when 'ClusterParameterGroup'
              @response['ParameterGroups'] << {name => @parameter_group}
              @parameter_group = {}
            end
          end
        end
      end
    end
  end
end
