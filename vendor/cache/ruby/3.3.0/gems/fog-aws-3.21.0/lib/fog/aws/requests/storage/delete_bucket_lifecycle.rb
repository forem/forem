module Fog
  module AWS
    class Storage
      class Real
        # Delete lifecycle configuration for a bucket
        #
        # @param bucket_name [String] name of bucket to delete lifecycle configuration from
        #
        # @return [Excon::Response] response:
        #   * status [Integer] - 204
        #
        # @see http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETElifecycle.html

        def delete_bucket_lifecycle(bucket_name)
          request({
                    :expects  => 204,
                    :headers  => {},
                    :bucket_name => bucket_name,
                    :method   => 'DELETE',
                    :query    => {'lifecycle' => nil}
                  })
        end
      end
    end
  end
end
