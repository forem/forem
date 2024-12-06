module Fog
  module Parsers
    module AWS
      module ECS
        require 'fog/aws/parsers/ecs/base'

        class TaskDefinition < Fog::Parsers::AWS::ECS::Base
          def start_element(name, attrs = [])
            super
            if @contexts.include?(name)
              @context.push(name)
            end
          end

          def end_element(name)
            super
            case name
            when 'taskDefinitionArn'
              @response[@result][@definition][name] = value
            when 'revision'
              @response[@result][@definition][name] = value.to_i
            when *@contexts
              @context.pop
            when 'member'
              case @context.last
              when 'volumes'
                @response[@result][@definition]['volumes'] << @volume
                @volume = {}
              when 'containerDefinitions'
                @response[@result][@definition]['containerDefinitions'] << @container
                @container = {}
              when 'command'
                @container['command'] ||= []
                @container['command'] << value
              when 'entryPoint'
                @container['entryPoint'] ||= []
                @container['entryPoint'] << value
              when 'links'
                @container['links'] ||= []
                @container['links'] << value
              when 'environment'
                @container['environment'] ||= []
                @container['environment'] << @environment
                @environment = {}
              when 'mountPoints'
                @container['mountPoints'] ||= []
                @container['mountPoints'] << @mountpoint
                @mountpoint = {}
              when 'portMappings'
                @container['portMappings'] ||= []
                @container['portMappings'] << @portmapping
                @portmapping = {}
              end
            when 'name'
              case @context.last
              when 'volumes'
                @volume[name] = value
              when 'containerDefinitions'
                @container[name] = value
              when 'environment'
                @environment[name] = value
              end
            when 'host'
              @volume[name] = @host
              @host = {}
            when 'sourcePath'
              @host[name] = value
            when 'cpu', 'memory'
              @container[name] = value.to_i
            when 'essential'
              @container[name] = value == 'true'
            when 'image'
              @container[name] = value
            when 'value'
              @environment[name] = value
            when 'readOnly'
              case @context.last
              when 'mountPoints'
                @mountpoint[name] = value == 'true'
              when 'volumesFrom'
                @volume_from[name] = value == 'true'
              end
            when 'containerPath', 'sourceVolume'
              @mountpoint[name] = value
            when 'containerPort', 'hostPort'
              @portmapping[name] = value.to_i
            when 'sourceContainer'
              @volume_from[name] = value
            end
          end
        end
      end
    end
  end
end
