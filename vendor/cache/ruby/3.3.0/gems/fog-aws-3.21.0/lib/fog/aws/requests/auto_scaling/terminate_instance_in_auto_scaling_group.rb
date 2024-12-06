module Fog
  module AWS
    class AutoScaling
      class Real
        require 'fog/aws/parsers/auto_scaling/terminate_instance_in_auto_scaling_group'

        # Terminates the specified instance. Optionally, the desired group size
        # can be adjusted.
        #
        # ==== Parameters
        # * instance_id<~String> - The ID of the EC2 instance to be terminated.
        # * should_decrement_desired_capacity<~Boolean> - Specifies whether
        #   (true) or not (false) terminating this instance should also
        #   decrement the size of the AutoScalingGroup.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        #     * 'TerminateGroupInAutoScalingInstanceResult'<~Hash>:
        #       * 'ActivityId'<~String> - Specifies the ID of the activity.
        #       * 'AutoScalingGroupName'<~String> - The name of the Auto
        #         Scaling group.
        #       * 'Cause'<~String> - Contains the reason the activity was
        #         begun.
        #       * 'Description'<~String> - Contains a friendly, more verbose
        #         description of the scaling activity.
        #       * 'EndTime'<~Time> - Provides the end time of this activity.
        #       * 'Progress'<~Integer> - Specifies a value between 0 and 100
        #         that indicates the progress of the activity.
        #       * 'StartTime'<~Time> - Provides the start time of this
        #         activity.
        #       * 'StatusCode'<~String> - Contains the current status of the
        #         activity.
        #       * 'StatusMessage'<~String> - Contains a friendly, more verbose
        #         description of the activity status.
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_TerminateInstanceInAutoScalingGroup.html
        #
        def terminate_instance_in_auto_scaling_group(instance_id, should_decrement_desired_capacity)
          request({
            'Action'                         => 'TerminateInstanceInAutoScalingGroup',
            'InstanceId'                     => instance_id,
            'ShouldDecrementDesiredCapacity' => should_decrement_desired_capacity.to_s,
            :parser                          => Fog::Parsers::AWS::AutoScaling::TerminateInstanceInAutoScalingGroup.new
          })
        end
      end

      class Mock
        def terminate_instance_in_auto_scaling_group(instance_id, should_decrement_desired_capacity)
          Fog::Mock.not_implemented
        end
      end
    end
  end
end
