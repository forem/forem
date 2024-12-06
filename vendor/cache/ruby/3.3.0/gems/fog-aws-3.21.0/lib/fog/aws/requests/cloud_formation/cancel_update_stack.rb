module Fog
  module AWS
    class CloudFormation
      class Real
        require 'fog/aws/parsers/cloud_formation/basic'

        # Cancels an update on the specified stack.
        #
        # @param stack_name String] Name of the stack to cancel update.
        #
        # @return [Excon::Response]
        #
        # @see http://docs.amazonwebservices.com/AWSCloudFormation/latest/APIReference/API_CancelUpdateStack.html

        def cancel_update_stack(stack_name)
          request(
            'Action'    => 'CancelUpdateStack',
            'StackName' => stack_name,
            :parser     => Fog::Parsers::AWS::CloudFormation::Basic.new
          )
        end
      end
    end
  end
end
