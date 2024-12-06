module Fog
  module AWS
    class Storage
      class Real
        # Deletes the cors configuration information set for the bucket.
        #
        # @param bucket_name [String] name of bucket to delete cors rules from
        #
        # @return [Excon::Response] response:
        #   * status [Integer] - 204
        #
        # @see http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEcors.html

        def delete_bucket_cors(bucket_name)
          request({
            :expects  => 204,
            :headers  => {},
            :bucket_name => bucket_name,
            :method   => 'DELETE',
            :query    => {'cors' => nil}
          })
        end
      end
    end
  end
end
