module Fog
  module Parsers
    module AWS
      module ECS
        require 'fog/aws/parsers/ecs/service'

        class DescribeServices < Fog::Parsers::AWS::ECS::Service
          def reset
            super
            @result = 'DescribeServicesResult'
            @response[@result] = { 'services' => [], 'failures' => [] }
            @service = {}
            @failure = {}
            @contexts = %w(failures services loadBalancers events deployments)
            @context = []
            @deployment = {}
            @load_balancer = {}
            @event = {}
          end
        end
      end
    end
  end
end
