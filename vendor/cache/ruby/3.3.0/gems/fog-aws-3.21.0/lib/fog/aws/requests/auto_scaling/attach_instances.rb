module Fog
  module AWS
    class AutoScaling
      class Real
        require 'fog/aws/parsers/auto_scaling/basic'

        # Removes one or more instances from the specified Auto Scaling group.
        #
        #  cli equiv:
        # `aws autoscaling attach-instances --instance-ids i-93633f9b --auto-scaling-group-name my-auto-scaling-group`
        #
        # ==== Parameters
        #
        #   * AutoScalingGroupName<~String> - The name of the Auto Scaling group``
        #   * 'InstanceIds'<~Array> - The list of Auto Scaling instances to detach.
        #
        # ==== See Also
        #
        # http://docs.aws.amazon.com/AutoScaling/latest/APIReference/API_AttachInstances.html

        ExpectedOptions[:asg_name] = %w[AutoScalingGroupName]
        ExpectedOptions[:instance_ids] = %w[InstanceIds]

        def attach_instances(auto_scaling_group_name, options = {})

          if instance_ids = options.delete('InstanceIds')
            options.merge!(AWS.indexed_param('InstanceIds.member.%d', [*instance_ids]))
          end

          request({
            'Action'               => 'AttachInstances',
            'AutoScalingGroupName' => auto_scaling_group_name,
            :parser                => Fog::Parsers::AWS::AutoScaling::Basic.new
          }.merge!(options))
        end
      end

      class Mock
        def attach_instances(auto_scaling_group_name, options = {})
          unexpected_options = options.keys - ExpectedOptions[:asg_name] - ExpectedOptions[:instance_ids]

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
