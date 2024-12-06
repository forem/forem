module Fog
  module AWS
    class ELB
      class Real
        require 'fog/aws/parsers/elb/configure_health_check'

        # Enables the client to define an application healthcheck for the instances.
        # See http://docs.amazonwebservices.com/ElasticLoadBalancing/latest/APIReference/index.html?API_ConfigureHealthCheck.html
        #
        # ==== Parameters
        # * lb_name<~String> - Name of the ELB
        # * health_check<~Hash> - A hash of parameters describing the health check
        #   * 'HealthyThreshold'<~Integer> - Specifies the number of consecutive
        #     health probe successes required before moving the instance to the Healthy state.
        #   * 'Interval'<~Integer> - Specifies the approximate interval, in seconds,
        #     between health checks of an individual instance.
        #   * 'Target'<~String> - Specifies the instance being checked.
        #     The protocol is either TCP or HTTP. The range of valid ports is one (1) through 65535.
        #   * 'Timeout'<~Integer> - Specifies the amount of time, in seconds,
        #   during which no response means a failed health probe.
        #   * 'UnhealthyThreshold'<~Integer> - Specifies the number of consecutive
        #     health probe failures required before moving the instance to the Unhealthy state.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        def configure_health_check(lb_name, health_check)
          params = {'LoadBalancerName' => lb_name}
          health_check.each {|key, value| params["HealthCheck.#{key}"] = value }

          request({
            'Action'           => 'ConfigureHealthCheck',
            :parser            => Fog::Parsers::AWS::ELB::ConfigureHealthCheck.new
          }.merge!(params))
        end
      end

      class Mock
        def configure_health_check(lb_name, health_check)
          if load_balancer = self.data[:load_balancers][lb_name]
            response = Excon::Response.new
            response.status = 200

            load_balancer['HealthCheck'] = health_check

            response.body = {
              'ResponseMetadata' => {
                'RequestId' => Fog::AWS::Mock.request_id
              },
              'ConfigureHealthCheckResult' => {
                'HealthCheck' => load_balancer['HealthCheck']
              }
            }

            response
          else
            raise Fog::AWS::ELB::NotFound
          end
        end
      end
    end
  end
end
