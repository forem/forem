module Fog
  module AWS
    class Storage
      class Real
        # Change bucket policy for an S3 bucket
        #
        # @param bucket_name [String] name of bucket to modify
        # @param policy [Hash] policy document
        #
        # @see http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTpolicy.html

        def put_bucket_policy(bucket_name, policy)
          request({
            :body     => Fog::JSON.encode(policy),
            :expects  => 204,
            :headers  => {},
            :bucket_name => bucket_name,
            :method   => 'PUT',
            :query    => {'policy' => nil}
          })
        end
      end

      class Mock
        #FIXME: You can't actually use the credentials for anything elsewhere in Fog
        #FIXME: Doesn't do any validation on the policy
        def put_bucket_policy(bucket_name, policy)
          if bucket = data[:buckets][bucket_name]
            bucket[:policy] = policy

            Excon::Response.new.tap do |response|
              response.body = { 'RequestId' => Fog::AWS::Mock.request_id }
              response.status = 200
            end
          else
            raise Fog::AWS::IAM::NotFound.new("The bucket with name #{bucket_name} cannot be found.")
          end
        end
      end
    end
  end
end
