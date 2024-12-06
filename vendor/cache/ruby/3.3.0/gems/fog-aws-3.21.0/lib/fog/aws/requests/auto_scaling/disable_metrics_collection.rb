module Fog
  module AWS
    class AutoScaling
      class Real
        require 'fog/aws/parsers/auto_scaling/basic'

        # Disables monitoring of group metrics for the Auto Scaling group
        # specified in AutoScalingGroupName. You can specify the list of
        # affected metrics with the Metrics parameter.
        #
        # ==== Parameters
        # * 'AutoScalingGroupName'<~String> - The name or ARN of the Auto
        #   Scaling group.
        # * options<~Hash>:
        #   * Metrics<~Array> - The list of metrics to disable. If no metrics
        #     are specified, all metrics are disabled.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_DisableMetricsCollection.html
        #
        def disable_metrics_collection(auto_scaling_group_name, options = {})
          if metrics = options.delete('Metrics')
            options.merge!(AWS.indexed_param('Metrics.member.%d', [*metrics]))
          end
          request({
            'Action'               => 'DisableMetricsCollection',
            'AutoScalingGroupName' => auto_scaling_group_name,
            :parser                => Fog::Parsers::AWS::AutoScaling::Basic.new
          }.merge!(options))
        end
      end

      class Mock
        def disable_metrics_collection(auto_scaling_group_name, options = {})
          unless self.data[:auto_scaling_groups].key?(auto_scaling_group_name)
            Fog::AWS::AutoScaling::ValidationError.new("Group #{auto_scaling_group_name} not found")
          end

          Fog::Mock.not_implemented
        end
      end
    end
  end
end
