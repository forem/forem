module Fog
  module AWS
    class Storage
      class Real
        # Get headers for an S3 bucket, used to verify if it exists and if you have permission to access it
        #
        # @param bucket_name [String] Name of bucket to read from
        #
        # @return [Excon::Response] 200 response implies it exists, 404 does not exist, 403 no permissions
        #   * body [String] Empty
        #   * headers [Hash]:
        #     * Content-Type [String] - MIME type of object
        #
        # @see http://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketHEAD.html
        #
        def head_bucket(bucket_name)
          unless bucket_name
            raise ArgumentError.new('bucket_name is required')
          end
          request({
            :expects    => 200,
            :bucket_name => bucket_name,
            :idempotent => true,
            :method     => 'HEAD',
          })
        end
      end

      class Mock # :nodoc:all
        def head_bucket(bucket_name)
          response = get_bucket(bucket_name)
          response.body = nil
          response
        end
      end
    end
  end
end
