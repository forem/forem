module Fog
  module AWS
    class AutoScaling
      class Real
        require 'fog/aws/parsers/auto_scaling/basic'

        # Sets or removes scale in instance protection from one or more instances from the specified
        # Auto Scaling group.
        #
        #  cli equiv:
        # `aws autoscaling set-instance-protection --instance-ids i-5f2e8a0d --auto-scaling-group-name my-asg --protected-from-scale-in`
        #
        # ==== Parameters
        #
        #   * AutoScalingGroupName<~String> - The name of the Auto Scaling group``
        #   * 'InstanceIds'<~Array> - The list of Auto Scaling instances to set or remove protection on.
        #   * 'ProtectedFromScaleIn'<~Boolean> - Protection state
        #
        # ==== See Also
        #
        # https://docs.aws.amazon.com/autoscaling/latest/APIReference/API_SetInstanceProtection.html

        ExpectedOptions[:asg_name] = %w[AutoScalingGroupName]
        ExpectedOptions[:instance_ids] = %w[InstanceIds]
        ExpectedOptions[:protected_from_scale_in] = %w[ProtectedFromScaleIn]

        def set_instance_protection(auto_scaling_group_name, options = {})
          if instance_ids = options.delete('InstanceIds')
            options.merge!(AWS.indexed_param('InstanceIds.member.%d', [*instance_ids]))
          end
          protected_from_scale_in = options.delete('ProtectedFromScaleIn')

          request({
            'Action'               => 'SetInstanceProtection',
            'AutoScalingGroupName' => auto_scaling_group_name,
            'ProtectedFromScaleIn' => protected_from_scale_in,
            :parser                => Fog::Parsers::AWS::AutoScaling::Basic.new
          }.merge!(options))
        end
      end

      class Mock
        def set_instance_protection(auto_scaling_group_name, options = {})
          unexpected_options = options.keys - \
            ExpectedOptions[:asg_name] - \
            ExpectedOptions[:instance_ids] - \
            ExpectedOptions[:protected_from_scale_in]

          unless unexpected_options.empty?
            raise Fog::AWS::AutoScaling::ValidationError.new("Options #{unexpected_options.join(',')} should not be included in request")
          end

          unless self.data[:auto_scaling_groups].key?(auto_scaling_group_name)
            raise Fog::AWS::AutoScaling::ValidationError.new('AutoScalingGroup name not found - null')
          end

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
