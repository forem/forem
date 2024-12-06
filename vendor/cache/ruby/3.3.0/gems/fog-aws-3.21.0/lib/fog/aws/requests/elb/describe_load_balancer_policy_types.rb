module Fog
  module AWS
    class ELB
      class Real
        require 'fog/aws/parsers/elb/describe_load_balancer_policy_types'

        # Describe all or specified load balancer policy types
        #
        # ==== Parameters
        # * type_name<~Array> - Specifies the name of the policy types. If no names are specified, returns the description of all the policy types defined by Elastic Load Balancing service.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        #     * 'DescribeLoadBalancerPolicyTypesResult'<~Hash>:
        #       * 'PolicyTypeDescriptions'<~Array>
        #         * 'Description'<~String> - A human-readable description of the policy type.
        #         * 'PolicyAttributeTypeDescriptions'<~Array>
        #           * 'AttributeName'<~String> - The name of the attribute associated with the policy type.
        #           * 'AttributeValue'<~String> - The type of attribute. For example, Boolean, Integer, etc.
        #           * 'Cardinality'<~String> - The cardinality of the attribute.
        #           * 'DefaultValue'<~String> - The default value of the attribute, if applicable.
        #           * 'Description'<~String> - A human-readable description of the attribute.
        #         * 'PolicyTypeName'<~String> - The name of the policy type.
        def describe_load_balancer_policy_types(type_names = [])
          params = Fog::AWS.indexed_param('PolicyTypeNames.member', [*type_names])
          request({
            'Action'  => 'DescribeLoadBalancerPolicyTypes',
            :parser   => Fog::Parsers::AWS::ELB::DescribeLoadBalancerPolicyTypes.new
          }.merge!(params))
        end
      end

      class Mock
        def describe_load_balancer_policy_types(type_names = [])
          type_names = [*type_names]
          policy_types = if type_names.any?
            type_names.map do |type_name|
              policy_type = self.data[:policy_types].find { |pt| pt['PolicyTypeName'] == type_name }
              raise Fog::AWS::ELB::PolicyTypeNotFound unless policy_type
              policy_type[1].dup
            end.compact
          else
            self.data[:policy_types].map { |policy_type| policy_type.dup }
          end

          response = Excon::Response.new
          response.status = 200

          response.body = {
            'ResponseMetadata' => {
              'RequestId' => Fog::AWS::Mock.request_id
            },
            'DescribeLoadBalancerPolicyTypesResult' => {
              'PolicyTypeDescriptions' => policy_types
            }
          }

          response
        end
      end
    end
  end
end
