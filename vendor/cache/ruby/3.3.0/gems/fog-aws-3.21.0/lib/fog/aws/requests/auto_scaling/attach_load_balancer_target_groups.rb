module Fog
  module AWS
    class AutoScaling
      class Real
        require 'fog/aws/parsers/auto_scaling/basic'

        # Attaches one or more load balancer target groups to the specified Auto Scaling
        # group.
        #
        # ==== Parameters
        # * auto_scaling_group_name<~String> - The name of the Auto Scaling
        # group.
        # * options<~Hash>:
        # 'TagetGroupARNs'<~Array> - A list of target group arns to use.
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_AttachLoadBalancerTargetGroups.html
        #

        ExpectedOptions[:attach_load_balancer_target_groups] = %w[TargetGroupARNs]

        def attach_load_balancer_target_groups(auto_scaling_group_name, options = {})
          if target_group_arns = options.delete('TargetGroupARNs')
            options.merge!(AWS.indexed_param('TargetGroupARNs.member.%d', *target_group_arns))
          end

          request({
            'Action'               => 'AttachLoadBalancerTargetGroups',
            'AutoScalingGroupName' => auto_scaling_group_name,
            :parser                => Fog::Parsers::AWS::AutoScaling::Basic.new
          }.merge!(options))
        end

      end

      class Mock
        def attach_load_balancer_target_groups(auto_scaling_group_name, options = {})
          unexpected_options = options.keys - ExpectedOptions[:attach_load_balancer_target_groups]

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
