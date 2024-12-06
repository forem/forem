module Fog
  module AWS
    class CloudFormation
      class Real
        require 'fog/aws/parsers/cloud_formation/describe_stacks'

        # Describe stacks.
        #
        # @param options [Hash]
        # @option options StackName [String] Name of the stack to describe.
        #
        # @return [Excon::Response]
        #   * body [Hash]:
        #     * Stacks [Array] - Matching stacks
        #       * stack [Hash]:
        #         * StackName [String] -
        #         * StackId [String] -
        #         * CreationTime [String] -
        #         * StackStatus [String] -
        #         * DisableRollback [String] -
        #         * Outputs [Array] -
        #           * output [Hash]:
        #             * OutputKey [String] -
        #             * OutputValue [String] -
        #
        # @see http://docs.amazonwebservices.com/AWSCloudFormation/latest/APIReference/API_DescribeStacks.html

        def describe_stacks(options = {})
          request({
            'Action'    => 'DescribeStacks',
            :parser     => Fog::Parsers::AWS::CloudFormation::DescribeStacks.new
          }.merge!(options))
        end
      end
    end
  end
end
