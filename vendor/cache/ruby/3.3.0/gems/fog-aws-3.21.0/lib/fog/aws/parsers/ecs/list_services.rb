module Fog
  module Parsers
    module AWS
      module ECS
        require 'fog/aws/parsers/ecs/base'

        class ListServices < Fog::Parsers::AWS::ECS::Base
          def reset
            super
            @result = 'ListServicesResult'
            @response[@result] = {'serviceArns' => []}
          end

          def end_element(name)
            super
            case name
            when 'member'
              @response[@result]['serviceArns'] << value
            when 'NextToken'
              @response[@result][name] = value
            end
          end
        end
      end
    end
  end
end
