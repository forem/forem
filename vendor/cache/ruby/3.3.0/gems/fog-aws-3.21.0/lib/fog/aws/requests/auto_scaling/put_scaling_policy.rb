module Fog
  module AWS
    class AutoScaling
      class Real
        require 'fog/aws/parsers/auto_scaling/put_scaling_policy'

        # Creates or updates a policy for an Auto Scaling group. To update an
        # existing policy, use the existing policy name and set the
        # parameter(s) you want to change. Any existing parameter not changed
        # in an update to an existing policy is not changed in this update
        # request.
        #
        # ==== Parameters
        # * adjustment_type<~String> - Specifies whether the scaling_adjustment
        #   is an absolute number or a percentage of the current capacity.
        # * auto_scaling_group_name<~String> - The name or ARN of the Auto
        #   Scaling group.
        # * policy_name<~String> - The name of the policy you want to create or
        #   update.
        # * scaling_adjustment<~Integer> - The number of instances by which to
        #   scale. AdjustmentType determines the interpretation of this number
        #   (e.g., as an absolute number or as a percentage of the existing
        #   Auto Scaling group size). A positive increment adds to the current
        #   capacity and a negative value removes from the current capacity.
        # * options<~Hash>:
        #   * 'Cooldown'<~Integer> - The amount of time, in seconds, after a
        #     scaling activity completes before any further trigger-related
        #     scaling activities can start
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        #     * 'PutScalingPolicyResult'<~Hash>:
        #       * 'PolicyARN'<~String> - A policy's Amazon Resource Name (ARN).
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_PutScalingPolicy.html
        #
        def put_scaling_policy(adjustment_type, auto_scaling_group_name, policy_name, scaling_adjustment, options = {})
          request({
            'Action'               => 'PutScalingPolicy',
            'AdjustmentType'       => adjustment_type,
            'AutoScalingGroupName' => auto_scaling_group_name,
            'PolicyName'           => policy_name,
            'ScalingAdjustment'    => scaling_adjustment,
            :parser                => Fog::Parsers::AWS::AutoScaling::PutScalingPolicy.new
          }.merge!(options))
        end
      end

      class Mock
        def put_scaling_policy(adjustment_type, auto_scaling_group_name, policy_name, scaling_adjustment, options = {})
          unless self.data[:auto_scaling_groups].key?(auto_scaling_group_name)
            raise Fog::AWS::AutoScaling::ValidationError.new('Auto Scaling Group name not found - null')
          end
          self.data[:scaling_policies][policy_name] = {
            'AdjustmentType'       => adjustment_type,
            'Alarms'               => [],
            'AutoScalingGroupName' => auto_scaling_group_name,
            'Cooldown'             => 0,
            'MinAdjustmentStep'    => 0,
            'PolicyARN'            => Fog::AWS::Mock.arn('autoscaling', self.data[:owner_id], "scalingPolicy:00000000-0000-0000-0000-000000000000:autoScalingGroupName/#{auto_scaling_group_name}:policyName/#{policy_name}", self.region),
            'PolicyName'           => policy_name,
            'ScalingAdjustment'    => scaling_adjustment
          }.merge!(options)

          response = Excon::Response.new
          response.status = 200
          response.body = {
            'ResponseMetadata' => { 'RequestId' => Fog::AWS::Mock.request_id }
          }
          response
        end
      end
    end
  end
end
