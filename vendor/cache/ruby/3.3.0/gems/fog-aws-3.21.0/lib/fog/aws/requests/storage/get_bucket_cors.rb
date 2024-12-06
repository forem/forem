module Fog
  module AWS
    class Storage
      class Real
        require 'fog/aws/parsers/storage/cors_configuration'

        # Gets the CORS configuration for an S3 bucket
        #
        # @param bucket_name [String] name of bucket to get access control list for
        #
        # @return [Excon::Response] response:
        #   * body [Hash]:
        #     * CORSConfiguration [Array]:
        #       * CORSRule [Hash]:
        #         * AllowedHeader [String] - Which headers are allowed in a pre-flight OPTIONS request through the Access-Control-Request-Headers header.
        #         * AllowedMethod [String] - Identifies an HTTP method that the domain/origin specified in the rule is allowed to execute.
        #         * AllowedOrigin [String] - One or more response headers that you want customers to be able to access from their applications (for example, from a JavaScript XMLHttpRequest object).
        #         * ExposeHeader [String] - One or more headers in the response that you want customers to be able to access from their applications (for example, from a JavaScript XMLHttpRequest object).
        #         * ID [String] - An optional unique identifier for the rule. The ID value can be up to 255 characters long. The IDs help you find a rule in the configuration.
        #         * MaxAgeSeconds [Integer] - The time in seconds that your browser is to cache the preflight response for the specified resource.
        #
        # @see http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETcors.html

        def get_bucket_cors(bucket_name)
          unless bucket_name
            raise ArgumentError.new('bucket_name is required')
          end
          request({
            :expects    => 200,
            :headers    => {},
            :bucket_name => bucket_name,
            :idempotent => true,
            :method     => 'GET',
            :parser     => Fog::Parsers::AWS::Storage::CorsConfiguration.new,
            :query      => {'cors' => nil}
          })
        end
      end

      class Mock # :nodoc:all
        require 'fog/aws/requests/storage/cors_utils'

        def get_bucket_cors(bucket_name)
          response = Excon::Response.new
          if cors = self.data[:cors][:bucket][bucket_name]
            response.status = 200
            if cors.is_a?(String)
              response.body = Fog::AWS::Storage.cors_to_hash(cors)
            else
              response.body = cors
            end
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
