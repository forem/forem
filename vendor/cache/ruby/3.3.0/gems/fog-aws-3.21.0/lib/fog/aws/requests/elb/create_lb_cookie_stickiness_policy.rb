module Fog
  module AWS
    class ELB
      class Real
        require 'fog/aws/parsers/elb/empty'

        # Create a Load Balancer Cookie Stickiness Policy
        #
        # ==== Parameters
        # * lb_name<~String> - Name of the ELB
        # * policy_name<~String> - The name of the policy being created. The name
        #   must be unique within the set of policies for this Load Balancer.
        # * cookie_expiration_period<~Integer> - The time period in seconds after
        #   which the cookie should be considered stale. Not specifying this
        #   parameter indicates that the sticky session will last for the duration of the browser session.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        def create_lb_cookie_stickiness_policy(lb_name, policy_name, cookie_expiration_period=nil)
          params = {'PolicyName' => policy_name, 'CookieExpirationPeriod' => cookie_expiration_period}

          request({
            'Action'           => 'CreateLBCookieStickinessPolicy',
            'LoadBalancerName' => lb_name,
            :parser            => Fog::Parsers::AWS::ELB::Empty.new
          }.merge!(params))
        end
      end

      class Mock
        def create_lb_cookie_stickiness_policy(lb_name, policy_name, cookie_expiration_period=nil)
          if load_balancer = self.data[:load_balancers][lb_name]
            response = Excon::Response.new
            response.status = 200

            create_load_balancer_policy(lb_name, policy_name, 'LBCookieStickinessPolicyType', {'CookieExpirationPeriod' => cookie_expiration_period})

            response.body = {
              'ResponseMetadata' => {
                'RequestId' => Fog::AWS::Mock.request_id
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
