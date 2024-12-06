module Fog
  module Parsers
    module AWS
      module ECS
        require 'fog/aws/parsers/ecs/base'

        class Service < Fog::Parsers::AWS::ECS::Base
          def start_element(name, attrs = [])
            super
            if @contexts.include?(name)
              @context.push(name)
            end
          end

          def end_element(name)
            super
            case name
            when *@contexts
              @context.pop
            when 'member'
              case @context.last
              when 'services'
                @response[@result]['services'] << @service
                @service = {}
              when 'loadBalancers'
                @service['loadBalancers'] ||= []
                @service['loadBalancers'] << @load_balancer
                @load_balancer = {}
              when 'events'
                @service['events'] ||= []
                @service['events'] << @event
                @event = {}
              when 'deployments'
                @service['deployments'] ||= []
                @service['deployments'] << @deployment
                @deployment = {}
              end
            when 'clusterArn', 'roleArn', 'serviceArn', 'serviceName'
              @service[name] = value
            when 'taskDefinition', 'status'
              case @context.last
              when 'service', 'services'
                @service[name] = value
              when 'deployments'
                @deployment[name] = value
              end
            when 'desiredCount', 'pendingCount', 'runningCount'
              case @context.last
              when 'service', 'services'
                @service[name] = value.to_i
              when 'deployments'
                @deployment[name] = value.to_i
              end
            when 'loadBalancerName', 'containerName'
              @load_balancer[name] = value
            when 'containerPort'
              @load_balancer[name] = value.to_i
            when 'createdAt'
              case @context.last
              when 'events'
                @event[name] = Time.parse(value)
              when 'deployments'
                @deployment[name] = Time.parse(value)
              end
            when 'id'
              case @context.last
              when 'events'
                @event[name] = value
              when 'deployments'
                @deployment[name] = value
              end
            when 'message'
              @event[name] = value
            when 'updatedAt'
              @deployment[name] = Time.parse(value)
            end
          end
        end
      end
    end
  end
end
