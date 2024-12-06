module Fog
  module Parsers
    module AWS
      module ECS
        require 'fog/aws/parsers/ecs/task'

        class StartTask < Fog::Parsers::AWS::ECS::Task
          def reset
            super
            @result = 'StartTaskResult'
            @response[@result] = {'failures' => [], 'tasks' => []}
            @contexts = %w(failures tasks containers overrides networkBindings containerOverrides)
            @context             = []
            @task                = {}
            @failure             = {}
            @container           = {}
            @net_binding         = {}
            @container_overrides = []
          end
        end
      end
    end
  end
end
