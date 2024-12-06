module Fog
  module Parsers
    module Redshift
      module AWS
        class UpdateClusterParameterGroupParser < Fog::Parsers::Base
          # :parameter_group_name - (String)
          # :parameter_group_status - (String)

          def reset
            @response = {}
          end

          def start_element(name, attrs = [])
            super
          end

          def end_element(name)
            super
            case name
            when 'ParameterGroupName', 'ParameterGroupStatus'
              @response[name] = value
            end
          end
        end
      end
    end
  end
end
