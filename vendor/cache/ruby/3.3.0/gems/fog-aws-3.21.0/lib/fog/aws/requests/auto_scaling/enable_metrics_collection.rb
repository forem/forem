module Fog
  module AWS
    class AutoScaling
      class Real
        require 'fog/aws/parsers/auto_scaling/basic'

        # Enables monitoring of group metrics for the Auto Scaling group
        # specified in auto_scaling_group_name. You can specify the list of
        # enabled metrics with the metrics parameter.
        #
        # Auto scaling metrics collection can be turned on only if the
        # instance_monitoring.enabled flag, in the Auto Scaling group's launch
        # configuration, is set to true.
        #
        # ==== Parameters
        # * 'AutoScalingGroupName'<~String>: The name or ARN of the Auto
        #   Scaling group
        # * options<~Hash>:
        #   * Granularity<~String>: The granularity to associate with the
        #     metrics to collect.
        #   * Metrics<~Array>: The list of metrics to collect. If no metrics
        #     are specified, all metrics are enabled.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_EnableMetricsCollection.html
        #
        def enable_metrics_collection(auto_scaling_group_name, granularity, options = {})
          if metrics = options.delete('Metrics')
            options.merge!(AWS.indexed_param('Metrics.member.%d', [*metrics]))
          end
          request({
            'Action'               => 'EnableMetricsCollection',
            'AutoScalingGroupName' => auto_scaling_group_name,
            'Granularity'          => granularity,
            :parser                => Fog::Parsers::AWS::AutoScaling::Basic.new
          }.merge!(options))
        end
      end

      class Mock
        def enable_metrics_collection(auto_scaling_group_name, granularity, options = {})
          unless self.data[:auto_scaling_groups].key?(auto_scaling_group_name)
            Fog::AWS::AutoScaling::ValidationError.new("Group #{auto_scaling_group_name} not found")
          end
          unless self.data[:metric_collection_types][:granularities].include?(granularity)
            Fog::AWS::AutoScaling::ValidationError.new('Valid metrics granularity type is: [1Minute].')
          end

          Fog::Mock.not_implemented
        end
      end
    end
  end
end
