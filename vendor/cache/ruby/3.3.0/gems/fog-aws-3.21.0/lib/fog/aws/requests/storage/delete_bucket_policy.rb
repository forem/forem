module Fog
  module AWS
    class Storage
      class Real
        # Delete policy for a bucket
        #
        # @param bucket_name [String] name of bucket to delete policy from
        #
        # @return [Excon::Response] response:
        #   * status [Integer] - 204
        #
        # @see http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEpolicy.html

        def delete_bucket_policy(bucket_name)
          request({
            :expects  => 204,
            :headers  => {},
            :bucket_name => bucket_name,
            :method   => 'DELETE',
            :query    => {'policy' => nil}
          })
        end
      end

      class Mock
        def delete_bucket_policy(bucket_name)
           if bucket = data[:buckets][bucket_name]
             bucket[:policy] = nil

             Excon::Response.new.tap do |response|
               response.body = { 'RequestId' => Fog::AWS::Mock.request_id }
               response.status = 200
             end
           else
             raise(Excon::Errors.status_error({:expects => 200}, response))
           end
        end
      end
    end
  end
end
