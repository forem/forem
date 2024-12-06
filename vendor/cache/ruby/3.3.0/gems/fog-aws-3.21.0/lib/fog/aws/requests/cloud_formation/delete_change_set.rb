module Fog
  module AWS
    class CloudFormation
      class Real
        require 'fog/aws/parsers/cloud_formation/basic'

        # Delete a change set.
        #
        # @param ChangeSetName [String] The name of the change set to delete.
        # @option options StackName [String] The Stack name or ID (ARN) that is associated with change set.
        #
        # @return [Excon::Response]
        #
        # @see http://docs.amazonwebservices.com/AWSCloudFormation/latest/APIReference/API_DeleteChangeSet.html

        def delete_change_set(change_set_name, options = {})
          options['ChangeSetName'] = change_set_name
          request({
            'Action'    => 'DeleteChangeSet',
            :parser     => Fog::Parsers::AWS::CloudFormation::Basic.new
          }.merge!(options))
        end
      end
    end
  end
end
