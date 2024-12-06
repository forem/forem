module Fog
  module AWS
    class ELB
      class Real
        require 'fog/aws/parsers/elb/describe_load_balancer_policies'

        # Describe all or specified load balancer policies
        #
        # ==== Parameters
        # * lb_name<~String> - The mnemonic name associated with the LoadBalancer. If no name is specified, the operation returns the attributes of either all the sample policies pre-defined by Elastic Load Balancing or the specified sample polices.
        # * names<~Array> - The names of LoadBalancer policies you've created or Elastic Load Balancing sample policy names.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        #     * 'DescribeLoadBalancerPoliciesResult'<~Hash>:
        #       * 'PolicyDescriptions'<~Array>
        #         * 'PolicyAttributeDescriptions'<~Array>
        #           * 'AttributeName'<~String> - The name of the attribute associated with the policy.
        #           * 'AttributeValue'<~String> - The value of the attribute associated with the policy.
        #         * 'PolicyName'<~String> - The name mof the policy associated with the LoadBalancer.
        #         * 'PolicyTypeName'<~String> - The name of the policy type.
        def describe_load_balancer_policies(lb_name = nil, names = [])
          params = Fog::AWS.indexed_param('PolicyNames.member', [*names])
          request({
            'Action'  => 'DescribeLoadBalancerPolicies',
            'LoadBalancerName' => lb_name,
            :parser   => Fog::Parsers::AWS::ELB::DescribeLoadBalancerPolicies.new
          }.merge!(params))
        end
      end

      class Mock
        def describe_load_balancer_policies(lb_name = nil, names = [])
          if lb_name
            raise Fog::AWS::ELB::NotFound unless load_balancer = self.data[:load_balancers][lb_name]
            names = [*names]
            policies = if names.any?
              names.map do |name|
                raise Fog::AWS::ELB::PolicyNotFound unless policy = load_balancer['Policies']['Proper'].find { |p| p['PolicyName'] == name }
                policy.dup
              end.compact
            else
              load_balancer['Policies']['Proper']
            end
          else
            policies = []
          end

          response = Excon::Response.new
          response.status = 200

          response.body = {
            'ResponseMetadata' => {
              'RequestId' => Fog::AWS::Mock.request_id
            },
            'DescribeLoadBalancerPoliciesResult' => {
              'PolicyDescriptions' => policies
            }
          }

          response
        end
      end
    end
  end
end
