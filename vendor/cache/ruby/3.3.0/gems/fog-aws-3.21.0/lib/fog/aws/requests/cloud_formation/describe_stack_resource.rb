module Fog
  module AWS
    class CloudFormation
      class Real
        require 'fog/aws/parsers/cloud_formation/describe_stack_resource'

        # Describe stack resource.
        #
        # @param options Hash]:
        #   * LogicalResourceId [String] Logical name of the resource as specified in the template
        #   * StackName [String] The name or the unique stack ID
        #
        # @return [Excon::Response]
        #   * body [Hash]:
        #     * StackResourceDetail [Hash] - Matching resources
        #         *Description [String] -
        #         * LastUpdatedTimestamp [Timestamp] -
        #         * LogicalResourceId [String] -
        #         * Metadata [String] -
        #         * PhysicalResourceId [String] -
        #         * ResourceStatus [String] -
        #         * ResourceStatusReason [String] -
        #         * ResourceType [String] -
        #         * StackId [String] -
        #         * StackName [String] -
        #
        # @see http://docs.amazonwebservices.com/AWSCloudFormation/latest/APIReference/API_DescribeStackResource.html

        def describe_stack_resource(logical_resource_id, stack_name )
          request(
            'Action'    => 'DescribeStackResource',
            'LogicalResourceId' => logical_resource_id,
            'StackName' => stack_name,
            :parser     => Fog::Parsers::AWS::CloudFormation::DescribeStackResource.new
          )
        end
      end
    end
  end
end
