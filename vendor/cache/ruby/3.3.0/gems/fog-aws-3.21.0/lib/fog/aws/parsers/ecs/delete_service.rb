module Fog
  module Parsers
    module AWS
      module ECS
        require 'fog/aws/parsers/ecs/service'

        class DeleteService < Fog::Parsers::AWS::ECS::Service
          def reset
            super
            @result = 'DeleteServiceResult'
            @response[@result] = {}
            @contexts = %w(service loadBalancers events deployments)
            @service       = {}
            @context       = []
            @deployment    = {}
            @load_balancer = {}
            @event         = {}
          end

          def end_element(name)
            super
            case name
            when 'service'
              @response[@result]['service'] = @service
            end
          end
        end
      end
    end
  end
end
