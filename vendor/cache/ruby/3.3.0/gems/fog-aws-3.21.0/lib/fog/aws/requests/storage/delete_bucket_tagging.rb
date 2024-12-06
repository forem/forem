module Fog
  module AWS
    class Storage
      class Real
        # Delete tagging for a bucket
        #
        # @param bucket_name [String] name of bucket to delete tagging from
        #
        # @return [Excon::Response] response:
        #   * status [Integer] - 204
        #
        # @see http://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketDELETEtagging.html

        def delete_bucket_tagging(bucket_name)
          request({
            :expects  => 204,
            :headers  => {},
            :bucket_name => bucket_name,
            :method   => 'DELETE',
            :query    => {'tagging' => nil}
          })
        end
      end

      class Mock # :nodoc:all
        def delete_bucket_tagging(bucket_name)
          response = Excon::Response.new
          if self.data[:buckets][bucket_name]
            self.data[:bucket_tagging].delete(bucket_name)
            response.status = 204
          else
            response.status = 404
            raise(Excon::Errors.status_error({:expects => 204}, response))
          end

          response
        end
      end
    end
  end
end
