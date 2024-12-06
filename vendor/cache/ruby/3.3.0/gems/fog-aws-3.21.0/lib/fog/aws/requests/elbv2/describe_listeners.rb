module Fog
  module AWS
    class ELBV2
      class Real
        require 'fog/aws/parsers/elbv2/describe_listeners'

        # Describe all or specified load balancers
        #
        # ==== Parameters
        # * 'LoadBalancerArn'<~String> - The Amazon Resource Name (ARN) of the load balancer
        # * options<~Hash>
        #   * 'Marker'<String> - Indicates where to begin in your list of load balancers
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        #     * 'DescribeListenersResult'<~Hash>:
        #       * 'Listeners'<~Array>
        #         * 'LoadBalancerArn'<~String> - The Amazon Resource Name (ARN) of the load balancer
        #         * 'Protocol'<~String> - The protocol for connections from clients to the load balancer
        #         * 'Port'<~String> - The port on which the load balancer is listening
        #         * 'DefaultActions'<~Array> - The default actions for the listener
        #           * 'Type'<~String> - The type of action
        #           * 'TargetGroupArn'<~String> - The Amazon Resource Name (ARN) of the target group. Specify only when Type is forward
        #       * 'NextMarker'<~String> - Marker to specify for next page
        def describe_listeners(load_balancer_arn, options = {})
          request({
            'Action'  => 'DescribeListeners',
            'LoadBalancerArn' => load_balancer_arn,
            :parser   => Fog::Parsers::AWS::ELBV2::DescribeListeners.new
          }.merge!(options))
        end
      end
    end
  end
end
