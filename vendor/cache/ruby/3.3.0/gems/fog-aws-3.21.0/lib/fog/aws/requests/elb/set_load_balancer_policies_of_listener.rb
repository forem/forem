module Fog
  module AWS
    class ELB
      class Real
        require 'fog/aws/parsers/elb/empty'

        # Associates, updates, or disables a policy with a listener on the
        # load balancer. Currently only zero (0) or one (1) policy can be
        # associated with a listener.
        #
        # ==== Parameters
        # * lb_name<~String> - Name of the ELB
        # * load_balancer_port<~Integer> - The external port of the LoadBalancer
        #   with which this policy has to be associated.

        # * policy_names<~Array> - List of policies to be associated with the
        #   listener. Currently this list can have at most one policy. If the
        #   list is empty, the current policy is removed from the listener.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        def set_load_balancer_policies_of_listener(lb_name, load_balancer_port, policy_names)
          params = {'LoadBalancerPort' => load_balancer_port}
          if policy_names.any?
            params.merge!(Fog::AWS.indexed_param('PolicyNames.member', policy_names))
          else
            params['PolicyNames'] = ''
          end

          request({
            'Action'           => 'SetLoadBalancerPoliciesOfListener',
            'LoadBalancerName' => lb_name,
            :parser            => Fog::Parsers::AWS::ELB::Empty.new
          }.merge!(params))
        end
      end

      class Mock
        def set_load_balancer_policies_of_listener(lb_name, load_balancer_port, policy_names)
          raise Fog::AWS::ELB::NotFound unless load_balancer = self.data[:load_balancers][lb_name]

          policy_names = [*policy_names]
          response = Excon::Response.new
          if policy_names.size > 1
            response.status = 409
            response.body = "<?xml version=\"1.0\"?><Response><Errors><Error><Code>InvalidConfigurationRequest</Code><Message>Requested configuration change is invalid.</Message></Error></Errors><RequestID>#{Fog::AWS::Mock.request_id}</RequestId></Response>"
            raise Excon::Errors.status_error({:expects => 200}, response)
          end

          unless listener = load_balancer['ListenerDescriptions'].find { |listener| listener['Listener']['LoadBalancerPort'] == load_balancer_port }
            response.status = 400
            response.body = "<?xml version=\"1.0\"?><Response><Errors><Error><Code>ListenerNotFound</Code><Message>LoadBalancer does not have a listnener configured at the given port.</Message></Error></Errors><RequestID>#{Fog::AWS::Mock.request_id}</RequestId></Response>"
            raise Excon::Errors.status_error({:expects => 200}, response)
          end

          unless load_balancer['Policies']['Proper'].find { |policy| policy['PolicyName'] == policy_names.first }
            response.status = 400
            response.body = "<?xml version=\"1.0\"?><Response><Errors><Error><Code>PolicyNotFound</Code><Message>One or more specified policies were not found.</Message></Error></Errors><RequestID>#{Fog::AWS::Mock.request_id}</RequestId></Response>"
            raise Excon::Errors.status_error({:expects => 200}, response)
          end if policy_names.any?

          listener['PolicyNames'] = policy_names

          response.status = 200
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
