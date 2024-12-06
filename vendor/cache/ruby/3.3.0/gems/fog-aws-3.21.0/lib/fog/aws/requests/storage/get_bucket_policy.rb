module Fog
  module AWS
    class Storage
      class Real
        # Get bucket policy for an S3 bucket
        #
        # @param bucket_name [String] name of bucket to get policy for
        #
        # @return [Excon::Response] response:
        #   * body [Hash] - policy document
        #
        # @see http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETpolicy.html

        def get_bucket_policy(bucket_name)
          unless bucket_name
            raise ArgumentError.new('bucket_name is required')
          end
          response = request({
            :expects    => 200,
            :headers    => {},
            :bucket_name => bucket_name,
            :idempotent => true,
            :method     => 'GET',
            :query      => {'policy' => nil}
          })
          response.body = Fog::JSON.decode(response.body) unless response.body.nil?
        end
      end
    end
  end
end
