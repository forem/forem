module Fog
  module Parsers
    module AWS
      module Elasticache
        require 'fog/aws/parsers/elasticache/base'

        class EngineDefaultsParser < Base
          def reset
            super
            reset_engine_defaults
          end

          def reset_engine_defaults
            @engine_defaults = {
              'CacheNodeTypeSpecificParameters' => [],
              'Parameters'                      => [],
            }
          end

          def start_element(name, attrs = [])
            case name
            when 'CacheNodeTypeSpecificParameter', 'Parameter'
              @parameter = {}
            when 'CacheNodeTypeSpecificValues'
              @parameter[name] = []
            when 'CacheNodeTypeSpecificValue'
              @node_specific_value = {}
            else
              super
            end
          end

          def end_element(name)
            case name
            when 'CacheParameterGroupFamily'
              @engine_defaults[name] = value
            when 'CacheNodeTypeSpecificParameter', 'Parameter'
              if not @parameter.empty?
                @engine_defaults["#{name}s"] << @parameter
              end
            when 'AllowedValues', 'DataType', 'Description', 'IsModifiable',
              'MinimumEngineVersion', 'ParameterName', 'ParameterValue', 'Source'
              @parameter[name] = value
            when 'CacheNodeType', 'Value'
              @node_specific_value[name] = value
            when 'CacheNodeTypeSpecificValue'
              if not @node_specific_value.empty?
                @parameter["#{name}s"] << @node_specific_value
              end
            else
              super
            end
          end
        end
      end
    end
  end
end
