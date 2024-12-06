module Fog
  module AWS
    class AutoScaling
      class Real
        require 'fog/aws/parsers/auto_scaling/basic'

        # Sets the health status of an instance.
        #
        # ==== Parameters
        # * health_status<~String> - The health status of the instance.
        #   "Healthy" means that the instance is healthy and should remain in
        #   service. "Unhealthy" means that the instance is unhealthy. Auto
        #   Scaling should terminate and replace it.
        # * instance_id<~String> - The identifier of the EC2 instance.
        # * options<~Hash>:
        #   * 'ShouldRespectGracePeriod'<~Boolean> - If true, this call should
        #   respect the grace period associated with the group.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_SetInstanceHealth.html
        #
        def set_instance_health(health_status, instance_id, options = {})
          request({
            'Action'       => 'SetInstanceHealth',
            'HealthStatus' => health_status,
            'InstanceId'   => instance_id,
            :parser        => Fog::Parsers::AWS::AutoScaling::Basic.new
          }.merge!(options))
        end
      end

      class Mock
        def set_instance_health(health_status, instance_id, options = {})
          unless self.data[:health_states].include?(health_status)
            raise Fog::AWS::AutoScaling::ValidationError.new('Valid instance health states are: [#{self.data[:health_states].join(", ")}].')
          end

          Fog::Mock.not_implemented
        end
      end
    end
  end
end
