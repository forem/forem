module Fog
  module AWS
    class CloudFormation
      class Real
        require 'fog/aws/parsers/cloud_formation/basic'

        # For a specified stack that is in the UPDATE_ROLLBACK_FAILED state,
        # continues rolling it back to the UPDATE_ROLLBACK_COMPLETE state.
        #
        # @param stack_name [String] The name or the unique ID of the stack that you want to continue rolling back.
        #
        # @return [Excon::Response]
        #
        # @see http://docs.amazonwebservices.com/AWSCloudFormation/latest/APIReference/API_ContinueUpdateRollback.html

        def continue_update_rollback(stack_name)
          request(
            'Action'    => 'ContinueUpdateRollback',
            'StackName' => stack_name,
            :parser     => Fog::Parsers::AWS::CloudFormation::Basic.new
          )
        end
      end
    end
  end
end
