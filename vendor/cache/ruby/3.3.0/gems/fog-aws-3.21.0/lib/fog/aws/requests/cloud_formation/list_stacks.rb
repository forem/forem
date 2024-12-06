module Fog
  module AWS
    class CloudFormation
      class Real
        require 'fog/aws/parsers/cloud_formation/list_stacks'

        # List stacks.
        #
        # @param options [Hash]
        #
        # @return [Excon::Response]
        #   * body [Hash]:
        #     * StackSummaries [Array] - Matching stacks
        #       * stack [Hash]:
        #         * StackId [String] -
        #         * StackName [String] -
        #         * TemplateDescription [String] -
        #         * CreationTime [Time] -
        #         * DeletionTime [Time] -
        #         * StackStatus [String] -
        #         * DeletionTime [String] -
        #
        #
        # @see http://docs.aws.amazon.com/AWSCloudFormation/latest/APIReference/API_ListStacks.html

        def list_stacks(options = {})
          request({
            'Action'    => 'ListStacks',
            :parser     => Fog::Parsers::AWS::CloudFormation::ListStacks.new
          }.merge!(options))
        end
      end
    end
  end
end
