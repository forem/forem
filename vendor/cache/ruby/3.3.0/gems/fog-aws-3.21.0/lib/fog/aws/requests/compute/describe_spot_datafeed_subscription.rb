module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/spot_datafeed_subscription'

        # Describe spot datafeed subscription
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - Id of request
        #     * 'spotDatafeedSubscription'<~Hash>:
        #       * 'bucket'<~String> - S3 bucket where data is stored
        #       * 'fault'<~Hash>:
        #         * 'code'<~String> - fault code
        #         * 'reason'<~String> - fault reason
        #       * 'ownerId'<~String> - AWS id of account owner
        #       * 'prefix'<~String> - prefix for datafeed items
        #       * 'state'<~String> - state of datafeed subscription
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeSpotDatafeedSubscription.html]
        def describe_spot_datafeed_subscription
          request({
            'Action'    => 'DescribeSpotDatafeedSubscription',
            :idempotent => true,
            :parser     => Fog::Parsers::AWS::Compute::SpotDatafeedSubscription.new
          })
        end
      end
    end
  end
end
