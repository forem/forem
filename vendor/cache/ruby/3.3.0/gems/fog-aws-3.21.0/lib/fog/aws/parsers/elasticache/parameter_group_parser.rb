module Fog
  module Parsers
    module AWS
      module Elasticache
        require 'fog/aws/parsers/elasticache/base'

        class ParameterGroupParser < Base
          def reset
            super
            reset_parameter_group
          end

          def reset_parameter_group
            @parameter_group = {}
          end

          def end_element(name)
            case name
            when 'Description', 'CacheParameterGroupName', 'CacheParameterGroupFamily'
              @parameter_group[name] = value
            else
              super
            end
          end
        end
      end
    end
  end
end
