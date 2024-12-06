module Fog
  module Parsers
    module AWS
      module Compute
        class DescribePlacementGroups < Fog::Parsers::Base
          def reset
            @placement_group = {}
            @response = { 'placementGroupSet' => [] }
          end

          def end_element(name)
            case name
            when 'item'
              @response['placementGroupSet'] << @placement_group
              @placement_group = {}
            when 'groupName', 'state', 'strategy'
              @placement_group[name] = value
            when 'requestId'
              @response[name] = value
            end
          end
        end
      end
    end
  end
end
