module Fog
  module Parsers
    module AWS
      module ECS
        require 'fog/aws/parsers/ecs/task_definition'

        class DeregisterTaskDefinition < Fog::Parsers::AWS::ECS::TaskDefinition
          def reset
            @response = {}
            @result = 'DeregisterTaskDefinitionResult'
            @definition = 'taskDefinition'
            @response[@result] = {
              @definition => {
                'volumes'              => [],
                'containerDefinitions' => []
              }
            }
            @contexts = %w(volumes containerDefinitions command entryPoint environment links mountPoints portMappings volumesFrom)
            @context     = []
            @volume      = {}
            @host        = {}
            @container   = {}
            @environment = {}
            @mountpoint  = {}
            @portmapping = {}
            @volume_from = {}
          end
        end
      end
    end
  end
end
