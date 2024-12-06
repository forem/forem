module Fog
  module AWS
    class ELB
      class Real
        require 'fog/aws/parsers/elb/empty'

        # Create Elastic Load Balancer Policy
        #
        # ==== Parameters
        # * lb_name<~String> - The name associated with the LoadBalancer for which the policy is being created. This name must be unique within the client AWS account.
        # * attributes<~Hash> - A list of attributes associated with the policy being created.
        #   * 'AttributeName'<~String> - The name of the attribute associated with the policy.
        #   * 'AttributeValue'<~String> - The value of the attribute associated with the policy.
        # * name<~String> - The name of the LoadBalancer policy being created. The name must be unique within the set of policies for this LoadBalancer.
        # * type_name<~String> - The name of the base policy type being used to create this policy. To get the list of policy types, use the DescribeLoadBalancerPolicyTypes action.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        def create_load_balancer_policy(lb_name, name, type_name, attributes = {})
          params = {}

          attribute_name = []
          attribute_value = []
          attributes.each do |name, value|
            attribute_name.push(name)
            attribute_value.push(value)
          end

          params.merge!(Fog::AWS.indexed_param('PolicyAttributes.member.%d.AttributeName', attribute_name))
          params.merge!(Fog::AWS.indexed_param('PolicyAttributes.member.%d.AttributeValue', attribute_value))

          request({
                    'Action'           => 'CreateLoadBalancerPolicy',
                    'LoadBalancerName' => lb_name,
                    'PolicyName'       => name,
                    'PolicyTypeName'   => type_name,
                    :parser            => Fog::Parsers::AWS::ELB::Empty.new
                  }.merge!(params))
        end
      end

      class Mock
        def create_load_balancer_policy(lb_name, name, type_name, attributes = {})
          if load_balancer = self.data[:load_balancers][lb_name]
            raise Fog::AWS::ELB::DuplicatePolicyName, name if policy = load_balancer['Policies']['Proper'].find { |p| p['PolicyName'] == name }
            raise Fog::AWS::ELB::PolicyTypeNotFound, type_name unless policy_type = self.data[:policy_types].find { |pt| pt['PolicyTypeName'] == type_name }

            response = Excon::Response.new

            attributes = attributes.map do |key, value|
              if key == "CookieExpirationPeriod" && !value
                value = 0
              end
              {"AttributeName" => key, "AttributeValue" => value.to_s}
            end

            load_balancer['Policies']['Proper'] << {
              'PolicyAttributeDescriptions' => attributes,
              'PolicyName' => name,
              'PolicyTypeName' => type_name
            }

            response.status = 200
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
