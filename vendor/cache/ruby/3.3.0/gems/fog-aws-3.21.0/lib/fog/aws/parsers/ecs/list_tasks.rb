module Fog
  module Parsers
    module AWS
      module ECS
        require 'fog/aws/parsers/ecs/base'

        class ListTasks < Fog::Parsers::AWS::ECS::Base
          def reset
            super
            @result = 'ListTasksResult'
            @response[@result] = {'taskArns' => []}
          end

          def end_element(name)
            super
            case name
            when 'member'
              @response[@result]['taskArns'] << value
            when 'NextToken'
              @response[@result][name] = value
            end
          end
        end
      end
    end
  end
end
