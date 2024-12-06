module Fog
  module AWS
    class AutoScaling
      class Real
        require 'fog/aws/parsers/auto_scaling/basic'

        # Adjusts the desired size of the AutoScalingGroup by initiating
        # scaling activities. When reducing the size of the group, it is not
        # possible to define which EC2 instances will be terminated. This
        # applies to any auto-scaling decisions that might result in
        # terminating instances.
        #
        # There are two common use cases for set_desired_capacity: one for
        # users of the Auto Scaling triggering system, and another for
        # developers who write their own triggering systems. Both use cases
        # relate to the concept of cooldown.
        #
        # In the first case, if you use the Auto Scaling triggering system,
        # set_desired_capacity changes the size of your Auto Scaling group
        # without regard to the cooldown period. This could be useful, for
        # example, if Auto Scaling did something unexpected for some reason. If
        # your cooldown period is 10 minutes, Auto Scaling would normally
        # reject requests to change the size of the group for that entire 10
        # minute period. The set_desired_capacity command allows you to
        # circumvent this restriction and change the size of the group before
        # the end of the cooldown period.
        #
        # In the second case, if you write your own triggering system, you can
        # use set_desired_capacity to control the size of your Auto Scaling
        # group. If you want the same cooldown functionality that Auto Scaling
        # offers, you can configure set_desired_capacity to honor cooldown by
        # setting the HonorCooldown parameter to true.
        #
        # ==== Parameters
        # * auto_scaling_group_name<~String> - The name of the Auto Scaling
        #   group.
        # * desired_capacity<~Integer> - The new capacity setting for the Auto
        #   Scaling group.
        # * options<~Hash>:
        #   * 'HonorCooldown'<~Boolean> - By default, set_desired_capacity
        #     overrides any cooldown period. Set to true if you want Auto
        #     Scaling to reject this request if the Auto Scaling group is in
        #     cooldown.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_SetDesiredCapacity.html
        #
        def set_desired_capacity(auto_scaling_group_name, desired_capacity, options = {})
          request({
            'Action'               => 'SetDesiredCapacity',
            'AutoScalingGroupName' => auto_scaling_group_name,
            'DesiredCapacity'      => desired_capacity,
            :parser                => Fog::Parsers::AWS::AutoScaling::Basic.new
          }.merge!(options))
        end
      end

      class Mock
        def set_desired_capacity(auto_scaling_group_name, desired_capacity, options = {})
          unless self.data[:auto_scaling_groups].key?(auto_scaling_group_name)
            Fog::AWS::AutoScaling::ValidationError.new('AutoScalingGroup name not found - null')
          end
          self.data[:auto_scaling_groups][auto_scaling_group_name]['DesiredCapacity'] = desired_capacity

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
