module Fog
  module AWS
    class Storage
      class Real
        require 'fog/aws/requests/storage/cors_utils'

        # Sets the cors configuration for your bucket. If the configuration exists, Amazon S3 replaces it.
        #
        # @param bucket_name [String] name of bucket to modify
        # @param cors [Hash]
        #   * CORSConfiguration [Array]:
        #     * ID [String]: A unique identifier for the rule.
        #     * AllowedMethod [String]: An HTTP method that you want to allow the origin to execute.
        #     * AllowedOrigin [String]: An origin that you want to allow cross-domain requests from.
        #     * AllowedHeader [String]: Specifies which headers are allowed in a pre-flight OPTIONS request via the Access-Control-Request-Headers header.
        #     * MaxAgeSeconds [String]: The time in seconds that your browser is to cache the preflight response for the specified resource.
        #     * ExposeHeader [String]: One or more headers in the response that you want customers to be able to access from their applications.
        #
        # @see http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTcors.html

        def put_bucket_cors(bucket_name, cors)
          data = Fog::AWS::Storage.hash_to_cors(cors)

          headers = {}
          headers['Content-MD5'] = Base64.encode64(OpenSSL::Digest::MD5.digest(data)).strip
          headers['Content-Type'] = 'application/json'
          headers['Date'] = Fog::Time.now.to_date_header

          request({
            :body     => data,
            :expects  => 200,
            :headers  => headers,
            :bucket_name => bucket_name,
            :method   => 'PUT',
            :query    => {'cors' => nil}
          })
        end
      end

      class Mock
        def put_bucket_cors(bucket_name, cors)
          self.data[:cors][:bucket][bucket_name] = Fog::AWS::Storage.hash_to_cors(cors)
        end
      end
    end
  end
end
