module Fog
  module Parsers
    module AWS
      module ECS
        require 'fog/aws/parsers/ecs/base'

        class Task < Fog::Parsers::AWS::ECS::Base
          def start_element(name, attrs = [])
            super
            if @contexts.include?(name)
              @context.push(name)
            end
          end

          def end_element(name)
            super
            case name
            when 'containerOverrides'
              @task['overrides'] ||= {}
              @task['overrides'][name] = @container_overrides
              @context.pop
            when 'task'
              @response[@result][name] = @task
            when *@contexts
              @context.pop
            when 'member'
              case @context.last
              when 'tasks'
                @response[@result]['tasks'] << @task
                @task = {}
              when 'containers'
                @task['containers'] ||= []
                @task['containers'] << @container
                @container = {}
              when 'networkBindings'
                @container['networkBindings'] ||= []
                @container['networkBindings'] << @net_binding
                @net_binding = {}
              when 'failures'
                @response[@result]['failures'] << @failure
                @failure = {}
              end
            when 'clusterArn', 'desiredStatus', 'startedBy', 'containerInstanceArn', 'taskDefinitionArn'
              @task[name] = value
            when 'taskArn', 'lastStatus'
              case @context.last
              when 'tasks'
                @task[name] = value
              when 'containers'
                @container[name] = value
              end
            when 'containerArn'
              @container[name] = value
            when 'exitCode'
              @container[name] = value.to_i
            when 'name'
              case @context.last
              when 'containers'
                @container[name] = value
              when 'containerOverrides'
                @container_overrides << value
              end
            when 'networkBindings'
              @container[name] = @net_bindings
            when 'bindIP'
              @net_binding[name] = value
            when 'hostPort', 'containerPort'
              @net_binding[name] = value.to_i
            when 'arn', 'reason'
              @failure[name] = value
            end
          end
        end
      end
    end
  end
end
