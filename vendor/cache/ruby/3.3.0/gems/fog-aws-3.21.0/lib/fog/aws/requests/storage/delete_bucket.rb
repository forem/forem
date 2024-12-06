module Fog
  module AWS
    class Storage
      class Real
        # Delete an S3 bucket
        #
        # @param bucket_name [String] name of bucket to delete
        #
        # @return [Excon::Response] response:
        #   * status [Integer] - 204
        #
        # @see http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETE.html

        def delete_bucket(bucket_name)
          request({
            :expects  => 204,
            :headers  => {},
            :bucket_name => bucket_name,
            :method   => 'DELETE'
          })
        end
      end

      class Mock # :nodoc:all
        def delete_bucket(bucket_name)
          response = Excon::Response.new
          if self.data[:buckets][bucket_name].nil?
            response.status = 404
            raise(Excon::Errors.status_error({:expects => 204}, response))
          elsif self.data[:buckets][bucket_name] && !self.data[:buckets][bucket_name][:objects].empty?
            response.status = 409
            raise(Excon::Errors.status_error({:expects => 204}, response))
          else
            self.data[:buckets].delete(bucket_name)
            response.status = 204
          end
          response
        end
      end
    end
  end
end
