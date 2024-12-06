module Fog
  module Parsers
    module AWS
      module ELB
        class DescribeLoadBalancerPolicyTypes < Fog::Parsers::Base
          def reset
            reset_policy_type
            reset_policy_attribute_type_description
            @results = { 'PolicyTypeDescriptions' => [] }
            @response = { 'DescribeLoadBalancerPolicyTypesResult' => {}, 'ResponseMetadata' => {} }
          end

          def reset_policy_type
            @policy_type = { 'Description' => '', 'PolicyAttributeTypeDescriptions' => [], 'PolicyTypeName' => '' }
          end

          def reset_policy_attribute_type_description
            @policy_attribute_type_description = { 'AttributeName' => '', 'AttributeType' => '', 'Cardinality' => '', 'DefaultValue' => '', 'Description' => '' }
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'PolicyAttributeTypeDescriptions'
              @in_policy_attribute_types = true
            end
          end

          def end_element(name)
            case name
            when 'member'
              if @in_policy_attribute_types
                @policy_type['PolicyAttributeTypeDescriptions'] << @policy_attribute_type_description
                reset_policy_attribute_type_description
              elsif !@in_policy_attribute_types
                @results['PolicyTypeDescriptions'] << @policy_type
                reset_policy_type
              end

            when 'Description'
              if @in_policy_attribute_types
                @policy_attribute_type_description[name] = value
              else
                @policy_type[name] = value
              end
            when 'PolicyTypeName'
              @policy_type[name] = value

            when 'PolicyAttributeTypeDescriptions'
              @in_policy_attribute_types = false

            when 'AttributeName', 'AttributeType', 'Cardinality', 'DefaultValue'
              @policy_attribute_type_description[name] = value

            when 'RequestId'
              @response['ResponseMetadata'][name] = value

            when 'DescribeLoadBalancerPolicyTypesResponse'
              @response['DescribeLoadBalancerPolicyTypesResult'] = @results
            end
          end
        end
      end
    end
  end
end
