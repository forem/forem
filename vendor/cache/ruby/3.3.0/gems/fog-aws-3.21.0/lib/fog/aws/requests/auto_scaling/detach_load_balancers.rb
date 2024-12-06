module Fog
  module AWS
    class AutoScaling
      class Real
        require 'fog/aws/parsers/auto_scaling/basic'

        # Removes one or more load balancers from the specified Auto Scaling
        # group.
        #
        # When you detach a load balancer, it enters the Removing state while
        # deregistering the instances in the group. When all instances are
        # deregistered, then you can no longer describe the load balancer using
        # DescribeLoadBalancers. Note that the instances remain running.
        #
        # ==== Parameters
        # * auto_scaling_group_name<~String> - The name of the Auto Scaling
        # group.
        # * options<~Hash>:
        # 'LoadBalancerNames'<~Array> - A list of LoadBalancers to use.
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_DetachLoadBalancers.html
        #

        ExpectedOptions[:detach_load_balancers] = %w[LoadBalancerNames]

        def detach_load_balancers(auto_scaling_group_name, options = {})
          if load_balancer_names = options.delete('LoadBalancerNames')
            options.merge!(AWS.indexed_param('LoadBalancerNames.member.%d', [*load_balancer_names]))
          end

          request({
            'Action'               => 'DetachLoadBalancers',
            'AutoScalingGroupName' => auto_scaling_group_name,
            :parser                => Fog::Parsers::AWS::AutoScaling::Basic.new
          }.merge!(options))
        end
      end

      class Mock
        def detach_load_balancers(auto_scaling_group_name, options = {})
          unexpected_options = options.keys - ExpectedOptions[:detach_load_balancers]

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
