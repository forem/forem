module Fog
  module AWS
    class ELB
      class Real
        require 'fog/aws/parsers/elb/empty'

        # Replaces the current set of policies associated with a port on which the back-end server is listening with a new set of policies.
        # After the policies have been created using CreateLoadBalancerPolicy, they can be applied here as a list.
        #
        # ==== Parameters
        # * lb_name<~String> - Name of the ELB
        # * instance_port<~Integer> - The port on the instance that the ELB will forward traffic to
        # * policy_names<~Array> - Array of Strings listing the policies to set for the backend port
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        def set_load_balancer_policies_for_backend_server(lb_name, instance_port, policy_names)
          params = {'InstancePort' => instance_port}
          if policy_names.any?
            params.merge!(Fog::AWS.indexed_param('PolicyNames.member', policy_names))
          else
            params['PolicyNames'] = ''
          end

          request({ 'Action' => 'SetLoadBalancerPoliciesForBackendServer',
                    'LoadBalancerName' => lb_name,
                    :parser => Fog::Parsers::AWS::ELB::Empty.new
                  }.merge!(params))
        end
      end

      class Mock
        def set_load_balancer_policies_for_backend_server(lb_name, instance_port, policy_names)
          if load_balancer = self.data[:load_balancers][lb_name]
            # Ensure policies exist
            policy_names.each do |policy_name|
              unless load_balancer['Policies']['Proper'].find { |p| p['PolicyName'] == policy_name }
                raise Fog::AWS::ELB::PolicyNotFound, "There is no policy with name #{policy_name} for load balancer #{lb_name}"
              end
            end

            # Update backend policies:
            description = load_balancer['BackendServerDescriptionsRemote'].find{|d| d["InstancePort"] == instance_port } || {}
            description["InstancePort"] = instance_port
            description["PolicyNames"] = policy_names
            load_balancer['BackendServerDescriptionsRemote'].delete_if{|d| d["InstancePort"] == instance_port }
            load_balancer['BackendServerDescriptionsRemote'] << description

            Excon::Response.new.tap do |response|
              response.status = 200
              response.body = {
                'ResponseMetadata' => {
                  'RequestId' => Fog::AWS::Mock.request_id
                }
              }
            end
          else
            raise Fog::AWS::ELB::NotFound
          end
        end
      end
    end
  end
end
