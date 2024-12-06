module Fog
  module Parsers
    module AWS
      module ECS
        require 'fog/aws/parsers/ecs/base'

        class DescribeClusters < Fog::Parsers::AWS::ECS::Base
          def reset
            super
            @result = 'DescribeClustersResult'
            @response[@result] = {}
            @contexts = %w(failures clusters)
            @context  = []
            @clusters = []
            @failures = []
            @cluster  = {}
            @failure  = {}
          end

          def start_element(name, attrs = [])
            super
            if @contexts.include?(name)
              @context.push(name)
            end
          end

          def end_element(name)
            super
            case name
            when 'clusterName', 'clusterArn', 'status'
              @cluster[name] = value
            when 'arn', 'reason'
              @failure[name] = value
            when 'member'
              case @context.last
              when 'clusters'
                @clusters << @cluster unless @cluster.empty?
                @cluster = {}
              when 'failures'
                @failures << @failure unless @failure.empty?
                @failure = {}
              end
            when 'clusters'
              @response[@result][name] = @clusters
              @context.pop
            when 'failures'
              @response[@result][name] = @failures
              @context.pop
            end
          end
        end
      end
    end
  end
end
