module Fog
  module AWS
    class AutoScaling
      class Real
        require 'fog/aws/parsers/auto_scaling/basic'

        # Removes one or more load balancer target groups from the specified
        # Auto Scaling group.
        #
        # ==== Parameters
        # * auto_scaling_group_name<~String> - The name of the Auto Scaling
        # group.
        # * options<~Hash>:
        # 'TargetGroupARNs'<~Array> - A list of target groups to detach.
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_DetachLoadBalancerTargetGroups.html
        #

        ExpectedOptions[:detach_load_balancer_target_groups] = %w[TargetGroupARNs]

        def detach_load_balancer_target_groups(auto_scaling_group_name, options = {})
          if target_group_arns = options.delete('TargetGroupARNs')
            options.merge!(AWS.indexed_param('TargetGroupARNs.member.%d', *target_group_arns))
          end

          request({
            'Action'               => 'DetachLoadBalancerTargetGroups',
            'AutoScalingGroupName' => auto_scaling_group_name,
            :parser                => Fog::Parsers::AWS::AutoScaling::Basic.new
          }.merge!(options))
        end
      end

      class Mock
        def detach_load_balancer_target_groups(auto_scaling_group_name, options = {})
          unexpected_options = options.keys - ExpectedOptions[:detach_load_balancer_target_groups]

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
