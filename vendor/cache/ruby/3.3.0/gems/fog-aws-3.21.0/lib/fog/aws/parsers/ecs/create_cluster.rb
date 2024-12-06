module Fog
  module Parsers
    module AWS
      module ECS
        require 'fog/aws/parsers/ecs/base'

        class CreateCluster < Fog::Parsers::AWS::ECS::Base
          def reset
            super
            @result = 'CreateClusterResult'
            @response[@result] = {}
            @cluster = {}
          end

          def end_element(name)
            super
            case name
            when 'clusterName', 'clusterArn', 'status'
              @cluster[name] = value
            when 'registeredContainerInstancesCount', 'runningTasksCount', 'pendingTasksCount'
              @cluster[name] = value.to_i
            when 'cluster'
              @response[@result]['cluster'] = @cluster
            end
          end
        end
      end
    end
  end
end
