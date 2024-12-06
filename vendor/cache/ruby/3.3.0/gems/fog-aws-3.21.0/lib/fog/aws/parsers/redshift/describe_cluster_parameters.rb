module Fog
  module Parsers
    module Redshift
      module AWS
        class DescribeClusterParameters < Fog::Parsers::Base
          # :marker - (String)
          # :parameters - (Array)
          #   :parameter_name - (String)
          #   :parameter_value - (String)
          #   :description - (String)
          #   :source - (String)
          #   :data_type - (String)
          #   :allowed_values - (String)
          #   :is_modifiable - (Boolean)
          #   :minimum_engine_version - (String)

          def reset
            @response = { 'Parameters' => [] }
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'Parameters'
              @parameter = {}
            end
          end

          def end_element(name)
            super
            case name
            when 'Marker'
              @response[name] = value
            when 'ParameterName', 'ParameterValue', 'Description', 'Source', 'DataType', 'AllowedValues', 'MinimumEngineVersion'
              @parameter[name] = value
            when 'IsModifiable'
              @parameter[name] = (value == "true")
            when 'Parameter'
              @response['Parameters'] << {name => @parameter}
              @parameter = {}
            end
          end
        end
      end
    end
  end
end
