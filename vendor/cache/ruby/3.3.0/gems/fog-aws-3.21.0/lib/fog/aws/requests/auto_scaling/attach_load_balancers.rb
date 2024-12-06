module Fog
  module AWS
    class AutoScaling
      class Real
        require 'fog/aws/parsers/auto_scaling/basic'

        # Attaches one or more load balancers to the specified Auto Scaling
        # group.
        #
        # ==== Parameters
        # * auto_scaling_group_name<~String> - The name of the Auto Scaling
        # group.
        # * options<~Hash>:
        # 'LoadBalancerNames'<~Array> - A list of LoadBalancers to use.
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_AttachLoadBalancers.html
        #

        ExpectedOptions[:attach_load_balancers] = %w[LoadBalancerNames]

        def attach_load_balancers(auto_scaling_group_name, options = {})
          if load_balancer_names = options.delete('LoadBalancerNames')
            options.merge!(AWS.indexed_param('LoadBalancerNames.member.%d', [*load_balancer_names]))
          end

          request({
            'Action'               => 'AttachLoadBalancers',
            'AutoScalingGroupName' => auto_scaling_group_name,
            :parser                => Fog::Parsers::AWS::AutoScaling::Basic.new
          }.merge!(options))
        end

      end

      class Mock
        def attach_load_balancers(auto_scaling_group_name, options = {})
          unexpected_options = options.keys - ExpectedOptions[:attach_load_balancers]

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
