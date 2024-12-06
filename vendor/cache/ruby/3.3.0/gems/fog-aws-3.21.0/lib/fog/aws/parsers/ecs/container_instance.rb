module Fog
  module Parsers
    module AWS
      module ECS
        require 'fog/aws/parsers/ecs/base'

        class ContainerInstance < Fog::Parsers::AWS::ECS::Base
          def start_element(name, attrs = [])
            super
            if @contexts.include?(name)
              @context.push(name)
            end
          end

          def end_element(name)
            super
            case name
            when 'stringSetValue'
              @context.pop
              case @context.last
              when 'remainingResources'
                @remaining_resource[name] = @string_set
              when 'registeredResources'
                @registered_resource[name] = @string_set
              end
              @string_set = []
            when *@contexts
              @context.pop
            when 'member'
              case @context.last
              when 'remainingResources'
                @container_instance['remainingResources'] ||= []
                @container_instance['remainingResources'] << @remaining_resource
                @remaining_resource = {}
              when 'registeredResources'
                @container_instance['registeredResources'] ||= []
                @container_instance['registeredResources'] << @registered_resource
                @registered_resource = {}
              when 'stringSetValue'
                @string_set << value.to_i
              end
            when 'longValue', 'integerValue'
              case @context.last
              when 'remainingResources'
                @remaining_resource[name] = value.to_i
              when 'registeredResources'
                @registered_resource[name] = value.to_i
              end
            when 'doubleValue'
              case @context.last
              when 'remainingResources'
                @remaining_resource[name] = value.to_f
              when 'registeredResources'
                @registered_resource[name] = value.to_f
              end
            when 'name', 'type'
              case @context.last
              when 'remainingResources'
                @remaining_resource[name] = value
              when 'registeredResources'
                @registered_resource[name] = value
              end
            when 'agentConnected'
              @container_instance[name] = value == 'true'
            when 'runningTasksCount', 'pendingTasksCount'
              @container_instance[name] = value.to_i
            when 'status', 'containerInstanceArn', 'ec2InstanceId'
              @container_instance[name] = value
            end
          end
        end
      end
    end
  end
end
