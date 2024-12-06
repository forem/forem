module Fog
  module AWS
    class ELB
      class Real
        require 'fog/aws/parsers/elb/empty'

        # Sets attributes of the load balancer
        #
        # The following attributes can be set:
        # * CrossZoneLoadBalancing (enable/disable)
        # * ConnectionDraining (enable/disable and timeout)
        # * Idle Connection Timeouts
        #
        # Still requires: AccessLog configuration
        #
        # http://docs.aws.amazon.com/ElasticLoadBalancing/latest/APIReference/API_ModifyLoadBalancerAttributes.html
        # ==== Parameters
        # * lb_name<~String> - Name of the ELB
        # * options<~Hash>
        #   * 'ConnectionDraining'<~Hash>:
        #     * 'Enabled'<~Boolean> whether to enable connection draining
        #     * 'Timeout'<~Integer> max time to keep existing conns open before deregistering instances
        #   * 'CrossZoneLoadBalancing'<~Hash>:
        #     * 'Enabled'<~Boolean> whether to enable cross zone load balancing
        #   * 'ConnectionSettings'<~Hash>:
        #     * 'IdleTimeout'<~Integer> time (in seconds) the connection is allowed to be idle (no data has been sent over the connection) before it is closed by the load balancer.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        def modify_load_balancer_attributes(lb_name, options)
          attributes = Fog::AWS.serialize_keys 'LoadBalancerAttributes', options
          request(attributes.merge(
            'Action'           => 'ModifyLoadBalancerAttributes',
            'LoadBalancerName' => lb_name,
            :parser            => Fog::Parsers::AWS::ELB::Empty.new
          ))
        end
      end

      class Mock
        def modify_load_balancer_attributes(lb_name, attributes)
          raise Fog::AWS::ELB::NotFound unless load_balancer = self.data[:load_balancers][lb_name]

          if attributes['CrossZoneLoadBalancing'] || attributes['ConnectionDraining'] || attributes['ConnectionSettings']
            load_balancer['LoadBalancerAttributes'].merge! attributes
          end

          response = Excon::Response.new

          response.status = 200
          response.body = {
            "ResponseMetadata" => {
              "RequestId" => Fog::AWS::Mock.request_id
            }
          }

          response
        end
      end
    end
  end
end
