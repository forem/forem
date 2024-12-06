module Fog
  module Parsers
    module AWS
      module ECS
        require 'fog/aws/parsers/ecs/base'

        class ListTaskDefinitions < Fog::Parsers::AWS::ECS::Base
          def reset
            super
            @result = 'ListTaskDefinitionsResult'
            @response[@result] = {'taskDefinitionArns' => []}
          end

          def end_element(name)
            super
            case name
            when 'member'
              @response[@result]['taskDefinitionArns'] << value
            when 'NextToken'
              @response[@result][name] = value
            end
          end
        end
      end
    end
  end
end
