module Fog
  module Parsers
    module AWS
      module AutoScaling
        class DescribeTerminationPolicyTypes < Fog::Parsers::Base
          def reset
            @results = { 'TerminationPolicyTypes' => [] }
            @response = { 'DescribeTerminationPolicyTypesResult' => {}, 'ResponseMetadata' => {} }
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'TerminationPolicyTypes'
              @in_termination_policy_types = true
            end
          end

          def end_element(name)
            case name
            when 'member'
              if @in_termination_policy_types
                @results['TerminationPolicyTypes'] << value
              end

            when 'TerminationPolicyTypes'
              @in_termination_policy_types = false

            when 'RequestId'
              @response['ResponseMetadata'][name] = value

            when 'DescribeTerminationPolicyTypesResponse'
              @response['DescribeTerminationPolicyTypesResult'] = @results
            end
          end
        end
      end
    end
  end
end
