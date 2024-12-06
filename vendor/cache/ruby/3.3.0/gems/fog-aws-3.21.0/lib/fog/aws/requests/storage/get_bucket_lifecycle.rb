module Fog
  module AWS
    class Storage
      class Real
        require 'fog/aws/parsers/storage/get_bucket_lifecycle'

        # Get bucket lifecycle configuration
        #
        # @param bucket_name [String] name of bucket to get lifecycle configuration for
        #
        # @return [Excon::Response] response:
        #   * body [Hash]:
        #     * Rules - object expire rules [Array]:
        #       * ID [String] - Unique identifier for the rule
        #       * Prefix [String] - Prefix identifying one or more objects to which the rule applies
        #       * Enabled [Boolean] - if rule is currently being applied
        #       * Days [Integer] - lifetime, in days, of the objects that are subject to the rule
        #
        # @see http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlifecycle.html

        def get_bucket_lifecycle(bucket_name)
          request({
                    :expects  => 200,
                    :headers  => {},
                    :bucket_name => bucket_name,
                    :idempotent => true,
                    :method   => 'GET',
                    :parser   => Fog::Parsers::AWS::Storage::GetBucketLifecycle.new,
                    :query    => {'lifecycle' => nil}
                  })
        end
      end
    end
  end
end
