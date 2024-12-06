module Fog
  module AWS
    class Storage
      class Real
        require 'fog/aws/parsers/storage/get_object_tagging'

        # Get tags for an S3 object
        #
        # @param bucket_name [String] Name of bucket to read from
        # @param object_name [String] Name of object to get tags for
        #
        # @return [Excon::Response] response:
        #   * body [Hash]:
        #     * ObjectTagging [Hash]:
        #       * Key [String] - tag key
        #       * Value [String] - tag value
        # @see https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectTagging.html

        def get_object_tagging(bucket_name, object_name)
          unless bucket_name
            raise ArgumentError.new('bucket_name is required')
          end
          unless object_name
            raise ArgumentError.new('object_name is required')
          end

          request({
            :expects => 200,
            :headers => {},
            :bucket_name => bucket_name,
            :object_name => object_name,
            :idempotent => true,
            :method => 'GET',
            :parser => Fog::Parsers::AWS::Storage::GetObjectTagging.new,
            :query => {'tagging' => nil}
          })
        end
      end
    end
  end
end
