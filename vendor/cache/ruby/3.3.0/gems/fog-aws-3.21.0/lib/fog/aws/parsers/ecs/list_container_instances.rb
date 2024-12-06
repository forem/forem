module Fog
  module Parsers
    module AWS
      module ECS
        require 'fog/aws/parsers/ecs/base'

        class ListContainerInstances < Fog::Parsers::AWS::ECS::Base
          def reset
            super
            @result = 'ListContainerInstancesResult'
            @response[@result] = {'containerInstanceArns' => []}
          end

          def end_element(name)
            super
            case name
            when 'member'
              @response[@result]['containerInstanceArns'] << value
            when 'NextToken'
              @response[@result][name] = value
            end
          end
        end
      end
    end
  end
end
