module Fog
  module AWS
    class CloudFormation
      class Real
        require 'fog/aws/parsers/cloud_formation/describe_account_limits'

        # Describe account_limits.
        #
        #
        # @return [Excon::Response]
        #   * body [Hash]:
        #     * AccountLimits [Array]
        #     * member [Hash]:
        #       * StackLimit [Integer]
        #
        # @see http://docs.amazonwebservices.com/AWSCloudFormation/latest/APIReference/API_DescribeAccountLimits.html

        def describe_account_limits()
          request(
            'Action' => 'DescribeAccountLimits',
            :parser  => Fog::Parsers::AWS::CloudFormation::DescribeAccountLimits.new
          )
        end
      end
    end
  end
end
