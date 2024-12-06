module Fog
  module AWS
    class ELB
      class Real
        require 'fog/aws/parsers/elb/empty'

        # Delet Elastic Load Balancer Listeners
        #
        # ==== Parameters
        # * lb_name<~String> - Name for the new ELB -- must be unique
        # * load_balancer_ports<~Array> - Array of client port numbers of the LoadBalancerListeners to remove
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        def delete_load_balancer_listeners(lb_name, load_balancer_ports)
          params = Fog::AWS.indexed_param('LoadBalancerPorts.member.%d', load_balancer_ports)

          request({
            'Action'           => 'DeleteLoadBalancerListeners',
            'LoadBalancerName' => lb_name,
            :parser            => Fog::Parsers::AWS::ELB::Empty.new
          }.merge!(params))
        end
      end

      class Mock
        def delete_load_balancer_listeners(lb_name, load_balancer_ports)
          raise Fog::AWS::ELB::NotFound unless load_balancer = self.data[:load_balancers][lb_name]

          response = Excon::Response.new
          response.status = 200

          load_balancer['ListenerDescriptions'].delete_if { |listener| load_balancer_ports.include? listener['Listener']['LoadBalancerPort'] }

          response.body = {
            'ResponseMetadata' => {
              'RequestId' => Fog::AWS::Mock.request_id
            }
          }

          response
        end
      end
    end
  end
end
