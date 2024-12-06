module Fog
  module AWS
    class CloudFormation
      class Real
        require 'fog/aws/parsers/cloud_formation/get_stack_policy'

        # Describe stacks.
        #
        # @param stack_name [String] The name or unique stack ID that is associated with the stack whose policy you want to get.
        #
        # @return [Excon::Response]
        #   * body [Hash]:
        #     * StackPolicyBody [String] - Structure containing the stack policy body.
        #
        # @see http://docs.amazonwebservices.com/AWSCloudFormation/latest/APIReference/API_GetStackPolicy.html

        def get_stack_policy(stack_name)
          request(
            'Action'    => 'GetStackPolicy',
            'StackName' => stack_name,
            :parser     => Fog::Parsers::AWS::CloudFormation::GetStackPolicy.new
          )
        end
      end
    end
  end
end
