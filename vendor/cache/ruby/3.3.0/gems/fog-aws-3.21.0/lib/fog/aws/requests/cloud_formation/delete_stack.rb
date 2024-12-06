module Fog
  module AWS
    class CloudFormation
      class Real
        require 'fog/aws/parsers/cloud_formation/basic'

        # Delete a stack.
        #
        # @param stack_name [String] Name of the stack to create.
        #
        # @return [Excon::Response]
        #
        # @see http://docs.amazonwebservices.com/AWSCloudFormation/latest/APIReference/API_DeleteStack.html

        def delete_stack(stack_name)
          request(
            'Action'    => 'DeleteStack',
            'StackName' => stack_name,
            :parser     => Fog::Parsers::AWS::CloudFormation::Basic.new
          )
        end
      end
    end
  end
end
