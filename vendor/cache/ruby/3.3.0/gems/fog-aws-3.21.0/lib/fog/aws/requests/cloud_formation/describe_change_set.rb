module Fog
  module AWS
    class CloudFormation
      class Real
        require 'fog/aws/parsers/cloud_formation/describe_change_set'

        # Describe change_set.
        #
        # * ChangeSetName [String] The name of the change set to describe.
        # @param options [Hash]
        # @option options StackName [String] Name of the stack for the change set.
        #
        # @return [Excon::Response]
        #   * body [Hash]:
        #         * ChangeSetId [String] -
        #         * ChangeSetName [String] -
        #         * Description [String] -
        #         * CreationTime [Time] -
        #         * ExecutionStatus [String] -
        #         * StackId [String] -
        #         * StackName [String] -
        #         * Status [String] -
        #         * StackReason [String] -
        #         * NotificationARNs [Array] -
        #           * NotificationARN [String] -
        #         * Parameters [Array] -
        #           * parameter [Hash]:
        #             * ParameterKey [String] -
        #             * ParameterValue [String] -
        #
        # @see http://docs.amazonwebservices.com/AWSCloudFormation/latest/APIReference/API_DescribeChangeSet.html

        def describe_change_set(change_set_name, options = {})
          options['ChangeSetName'] = change_set_name
          request({
            'Action'    => 'DescribeChangeSet',
            :parser     => Fog::Parsers::AWS::CloudFormation::DescribeChangeSet.new
          }.merge!(options))
        end
      end
    end
  end
end
