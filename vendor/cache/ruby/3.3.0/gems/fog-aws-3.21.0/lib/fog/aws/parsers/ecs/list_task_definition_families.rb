module Fog
  module Parsers
    module AWS
      module ECS
        require 'fog/aws/parsers/ecs/base'

        class ListTaskDefinitionFamilies < Fog::Parsers::AWS::ECS::Base
          def reset
            super
            @result = 'ListTaskDefinitionFamiliesResult'
            @response[@result] = {'families' => []}
          end

          def end_element(name)
            super
            case name
            when 'member'
              @response[@result]['families'] << value
            when 'NextToken'
              @response[@result][name] = value
            end
          end
        end
      end
    end
  end
end
