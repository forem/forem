module Fog
  module Parsers
    module AWS
      module Elasticache
        require 'fog/aws/parsers/elasticache/parameter_group_parser'

        class DescribeParameterGroups < ParameterGroupParser
          def reset
            super
            @response['CacheParameterGroups'] = []
          end

          def end_element(name)
            case name
            when 'CacheParameterGroup'
              @response["#{name}s"] << @parameter_group
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
