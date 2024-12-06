module Fog
  module AWS
    class CloudFormation
      class Real
        require 'fog/aws/parsers/cloud_formation/basic'

        # Sets a stack policy for a specified stack.
        #
        # @param stack_name [String] Name or unique stack ID that you want to associate a policy with.
        # * options [Hash]:
        #   * StackPolicyBody [String] Structure containing the stack policy body.
        #   or (one of the two StackPolicy parameters is required)
        #   * StackPolicyURL [String] URL of file containing the stack policy.
        #   * Parameters [Hash] Hash of providers to supply to StackPolicy
        #
        # @return [Excon::Response]:
        #
        # @see http://docs.amazonwebservices.com/AWSCloudFormation/latest/APIReference/API_SetStackPolicy.html

        def set_stack_policy(stack_name, options = {})
          params = {}

          if options['StackPolicyBody']
            params['StackPolicyBody'] = options['StackPolicyBody']
          elsif options['StackPolicyURL']
            params['StackPolicyURL'] = options['StackPolicyURL']
          end

          request({
            'Action'    => 'SetStackPolicy',
            'StackName' => stack_name,
            :parser     => Fog::Parsers::AWS::CloudFormation::Basic.new
          }.merge!(params))
        end
      end
    end
  end
end
