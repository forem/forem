module Fog
  module Parsers
    module AWS
      module ECS
        require 'fog/aws/parsers/ecs/task'

        class StopTask < Fog::Parsers::AWS::ECS::Task
          def reset
            super
            @result = 'StopTaskResult'
            @response[@result] = {'task' => {}}
            @contexts = %w(task containers overrides networkBindings containerOverrides)
            @context             = []
            @task                = {}
            @container           = {}
            @net_binding         = {}
            @container_overrides = []
          end
        end
      end
    end
  end
end
