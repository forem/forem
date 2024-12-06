module Fog
  module AWS
    class Storage
      class Real
        require 'fog/aws/parsers/storage/get_bucket_tagging'

        # Get tags for an S3 bucket
        #
        # @param bucket_name [String] name of bucket to get tags for
        #
        # @return [Excon::Response] response:
        #   * body [Hash]:
        #     * BucketTagging [Hash]:
        #       * Key [String] - tag key
        #       * Value [String] - tag value
        # @see http://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketGETtagging.html

        def get_bucket_tagging(bucket_name)
          unless bucket_name
            raise ArgumentError.new('bucket_name is required')
          end
          request({
            :expects    => 200,
            :headers    => {},
            :bucket_name => bucket_name,
            :idempotent => true,
            :method     => 'GET',
            :parser     => Fog::Parsers::AWS::Storage::GetBucketTagging.new,
            :query      => {'tagging' => nil}
          })
        end
      end

      class Mock # :nodoc:all
        def get_bucket_tagging(bucket_name)
          response = Excon::Response.new
          if self.data[:buckets][bucket_name] && self.data[:bucket_tagging][bucket_name]
            response.status = 200
            response.body = {'BucketTagging' => self.data[:bucket_tagging][bucket_name]}
          else
            response.status = 404
            raise(Excon::Errors.status_error({:expects => 200}, response))
          end
          response
        end
      end
    end
  end
end
