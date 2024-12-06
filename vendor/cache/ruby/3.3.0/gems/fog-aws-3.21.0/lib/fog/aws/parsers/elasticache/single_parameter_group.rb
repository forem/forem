module Fog
  module Parsers
    module AWS
      module Elasticache
        require 'fog/aws/parsers/elasticache/parameter_group_parser'

        class SingleParameterGroup < ParameterGroupParser
          def end_element(name)
            case name
            when 'CacheParameterGroup'
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
