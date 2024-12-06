module Fog
  module Parsers
    module AWS
      module ECS
        require 'fog/aws/parsers/ecs/task_definition'

        class RegisterTaskDefinition < Fog::Parsers::AWS::ECS::TaskDefinition
          def reset
            super
            @result = 'RegisterTaskDefinitionResult'
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
