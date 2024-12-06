module Fog
  module AWS
    class CloudFormation
      class Real
        require 'fog/aws/parsers/cloud_formation/describe_stack_resources'

        # Describe stack resources.
        #
        # @param options Hash]:
        #   * PhysicalResourceId [String] name or unique identifier that corresponds to a physical instance ID
        #   or (one of PhysicalResourceId and StackName is required)
        #   * StackName [String] Only return events related to this stack name
        #   * LogicalResourceId [String] Logical name of the resource as specified in the template
        #
        # @return [Excon::Response]
        #   * body [Hash]:
        #     * StackResources [Array] - Matching resources
        #       * resource [Hash]:
        #         * StackId [String] -
        #         * StackName [String] -
        #         * LogicalResourceId [String] -
        #         * PhysicalResourceId [String] -
        #         * ResourceType [String] -
        #         * Timestamp [Time] -
        #         * ResourceStatus [String] -
        #
        # @see http://docs.amazonwebservices.com/AWSCloudFormation/latest/APIReference/API_DescribeStackResources.html

        def describe_stack_resources(options = {})
          request({
            'Action'    => 'DescribeStackResources',
            :parser     => Fog::Parsers::AWS::CloudFormation::DescribeStackResources.new
          }.merge!(options))
        end
      end
    end
  end
end
