module Fog
  module Parsers
    module AWS
      module ECS
        require 'fog/aws/parsers/ecs/base'

        class ListClusters < Fog::Parsers::AWS::ECS::Base
          def reset
            super
            @result = 'ListClustersResult'
            @response[@result] = {'clusterArns' => []}
          end

          def end_element(name)
            super
            case name
            when 'member'
              @response[@result]['clusterArns'] << value
            when 'NextToken'
              @response[@result][name] = value
            end
          end
        end
      end
    end
  end
end
