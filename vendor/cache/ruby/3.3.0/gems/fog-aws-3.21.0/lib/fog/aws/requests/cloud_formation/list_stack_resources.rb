module Fog
  module AWS
    class CloudFormation
      class Real
        require 'fog/aws/parsers/cloud_formation/list_stack_resources'

        # List stack resources.
        #
        # @param options [Hash]
        # @option options StackName [String] Name of the stack to describe.
        #
        # @return [Excon::Response]
        #   * body [Hash]:
        #     * StackResourceSummaries [Array] - Matching stacks
        #       * resources [Hash]:
        #         * ResourceStatus [String] -
        #         * LogicalResourceId [String] -
        #         * PhysicalResourceId [String] -
        #         * ResourceType [String] -
        #         * LastUpdatedTimestamp [Time] -
        #
        #
        # @see http://docs.aws.amazon.com/AWSCloudFormation/latest/APIReference/API_ListStacks.html

        def list_stack_resources(options = {})
          request({
            'Action'    => 'ListStackResources',
            :parser     => Fog::Parsers::AWS::CloudFormation::ListStackResources.new
          }.merge!(options))
        end
      end
    end
  end
end
