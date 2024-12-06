module Fog
  module AWS
    class CloudFormation
      class Real
        require 'fog/aws/parsers/cloud_formation/list_change_sets'

        # List change sets.
        #
        # @param stack_name String] Name or the ARN of the stack for which you want to list change sets.
        #
        # @option options StackName [String] Name of the stack to describe.
        #
        # @return [Excon::Response]
        #   * body [Hash]:
        #     * Summaries [Array] - Matching change sets
        #       * stack [Hash]:
        #         * ChangeSetId [String] -
        #         * ChangeSetName [String] -
        #         * Description [String] -
        #         * CreationTime [Time] -
        #         * ExecutionStatus [String] -
        #         * StackId [String] -
        #         * StackName [String] -
        #         * Status [String] -
        #         * StackReason [String] -
        #
        #
        # @see http://docs.aws.amazon.com/AWSCloudFormation/latest/APIReference/API_ListChangeSets.html

        def list_change_sets(stack_name, options = {})
          request({
            'Action'    => 'ListChangeSets',
            'StackName' => stack_name,
            :parser     => Fog::Parsers::AWS::CloudFormation::ListChangeSets.new
          }.merge!(options))
        end
      end
    end
  end
end
