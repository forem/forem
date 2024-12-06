module Fog
  module Parsers
    module Redshift
      module AWS
        class CreateClusterParameterGroup < Fog::Parsers::Base
          # :parameter_group_name - (String)
          # :parameter_group_family - (String)
          # :description - (String)

          def reset
            @response = {'ClusterParameterGroup'=>{}}
          end

          def start_element(name, attrs = [])
            super
          end

          def end_element(name)
            super
            case name
            when 'ParameterGroupName', 'ParameterGroupFamily', 'Description'
              @response['ClusterParameterGroup'][name] = value
            end
          end
        end
      end
    end
  end
end
