module Fog
  module AWS
    class AutoScaling
      class Real
        require 'fog/aws/parsers/auto_scaling/basic'

        # Runs the policy you create for your Auto Scaling group in
        # put_scaling_policy.
        #
        # ==== Parameters
        # * 'PolicyName'<~String> - The name or PolicyARN of the policy you
        #   want to run.
        # * options<~Hash>:
        #   * 'AutoScalingGroupName'<~String> - The name or ARN of the Auto
        #     Scaling group.
        #   * 'HonorCooldown'<~Boolean> - Set to true if you want Auto Scaling
        #     to reject this request if the Auto Scaling group is in cooldown.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_ExecutePolicy.html
        #
        def execute_policy(policy_name, options = {})
          request({
            'Action'     => 'ExecutePolicy',
            'PolicyName' => policy_name,
            :parser      => Fog::Parsers::AWS::AutoScaling::Basic.new
          }.merge!(options))
        end
      end

      class Mock
        def execute_policy(policy_name, options = {})
          Fog::Mock.not_implemented
        end
      end
    end
  end
end
