module Fog
  module Parsers
    module AWS
      module ECS
        require 'fog/aws/parsers/ecs/container_instance'

        class DescribeContainerInstances < Fog::Parsers::AWS::ECS::ContainerInstance
          def reset
            super
            @result = 'DescribeContainerInstancesResult'
            @response[@result] = {
              'containerInstances' => [],
              'failures' => []
            }
            @contexts = %w(containerInstances registeredResources remainingResources stringSetValue)
            @context = []
            @container_instance  = {}
            @registered_resource = {}
            @remaining_resource  = {}
            @string_set = []
          end

          def end_element(name)
            super
            case name
            when 'member'
              case @context.last
              when 'containerInstances'
                @response[@result]['containerInstances'] << @container_instance
                @container_instance = {}
              end
            end
          end
        end
      end
    end
  end
end
