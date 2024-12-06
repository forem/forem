module Fog
  module Parsers
    module AWS
      module ELB
        class DescribeLoadBalancerPolicies < Fog::Parsers::Base
          def reset
            reset_policy
            reset_policy_attribute_description
            @results = { 'PolicyDescriptions' => [] }
            @response = { 'DescribeLoadBalancerPoliciesResult' => {}, 'ResponseMetadata' => {} }
          end

          def reset_policy
            @policy = { 'PolicyAttributeDescriptions' => [], 'PolicyName' => '', 'PolicyTypeName' => '' }
          end

          def reset_policy_attribute_description
            @policy_attribute_description = { 'AttributeName' => '', 'AttributeValue' => '' }
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'PolicyAttributeDescriptions'
              @in_policy_attributes = true
            end
          end

          def end_element(name)
            case name
            when 'member'
              if @in_policy_attributes
                @policy['PolicyAttributeDescriptions'] << @policy_attribute_description
                reset_policy_attribute_description
              elsif !@in_policy_attributes
                @results['PolicyDescriptions'] << @policy
                reset_policy
              end

            when 'PolicyName', 'PolicyTypeName'
              @policy[name] = value

            when 'PolicyAttributeDescriptions'
              @in_policy_attributes = false

            when 'AttributeName', 'AttributeValue'
              @policy_attribute_description[name] = value

            when 'RequestId'
              @response['ResponseMetadata'][name] = value

            when 'DescribeLoadBalancerPoliciesResponse'
              @response['DescribeLoadBalancerPoliciesResult'] = @results
            end
          end
        end
      end
    end
  end
end
