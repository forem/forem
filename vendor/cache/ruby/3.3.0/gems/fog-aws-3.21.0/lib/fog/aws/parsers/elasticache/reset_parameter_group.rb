module Fog
  module Parsers
    module AWS
      module Elasticache
        require 'fog/aws/parsers/elasticache/parameter_group_parser'

        class ResetParameterGroup < ParameterGroupParser
          def reset
            super
            @response['ResetCacheParameterGroupResult'] = []
          end

          def end_element(name)
            case name
            when 'ResetCacheParameterGroupResult'
              @response[name] = @parameter_group
              reset_parameter_group
            else
              super
            end
          end
        end
      end
    end
  end
end
