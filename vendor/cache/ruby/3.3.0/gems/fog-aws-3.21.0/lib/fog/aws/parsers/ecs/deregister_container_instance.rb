module Fog
  module Parsers
    module AWS
      module ECS
        require 'fog/aws/parsers/ecs/container_instance'

        class DeregisterContainerInstance < Fog::Parsers::AWS::ECS::ContainerInstance
          def reset
            super
            @result = 'DeregisterContainerInstanceResult'
            @response[@result] = {}
            @contexts = %w(registeredResources remainingResources stringSetValue)
            @context = []
            @container_instance  = {}
            @registered_resource = {}
            @remaining_resource  = {}
            @string_set = []
          end

          def end_element(name)
            super
            case name
            when 'containerInstance'
              @response[@result][name] = @container_instance
            end
          end
        end
      end
    end
  end
end
