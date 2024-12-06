module Fog
  module AWS
    class CDN
      class Real
        require 'fog/aws/parsers/cdn/streaming_distribution'

        # Update a streaming distribution in CloudFront.
        #
        # @param distribution_id [String] - Id of distribution to update config for.
        # @param options [Hash] - Config for distribution.
        #
        #   REQUIRED:
        #   * S3Origin [Hash]:
        #     * DNSName [String] Origin to associate with distribution, ie 'mybucket.s3.amazonaws.com'.
        #   OPTIONAL:
        # @option options CallerReference [String] Used to prevent replay, defaults to Time.now.to_i.to_s
        # @option options Comment [String] Optional comment about distribution
        # @option options CNAME [Array] Optional array of strings to set as CNAMEs
        # @option options Enabled [Boolean] Whether or not distribution should accept requests, defaults to true
        # @option options Logging [Hash]: Optional logging config
        #   * Bucket [String] Bucket to store logs in, ie 'mylogs.s3.amazonaws.com'
        #   * Prefix String] Optional prefix for log filenames, ie 'myprefix/'
        #
        # @return [Excon::Response]
        #   * body [Hash]:
        #     * DomainName [String] - Domain name of distribution.
        #     * Id [String] - Id of distribution.
        #     * LastModifiedTime [String] - Timestamp of last modification of distribution.
        #     * Status [String] - Status of distribution.
        #     * StreamingDistributionConfig [Array]:
        #       * CallerReference [String] - Used to prevent replay, defaults to Time.now.to_i.to_s.
        #       * CNAME [Array] - Array of associated cnames.
        #       * Comment [String] - Comment associated with distribution.
        #       * Enabled [Boolean] - Whether or not distribution is enabled.
        #       * Logging [Hash]:
        #         * Bucket [String] - Bucket logs are stored in.
        #         * Prefix [String] - Prefix logs are stored with.
        #       * Origin [String] - S3 origin bucket.
        #       * TrustedSigners [Array] - Trusted signers.
        #
        # @see http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/PutStreamingDistribution.html

        def put_streaming_distribution_config(distribution_id, etag, options = {})
          data = '<?xml version="1.0" encoding="UTF-8"?>'
          data << "<StreamingDistributionConfig xmlns=\"http://cloudfront.amazonaws.com/doc/#{@version}/\">"
          for key, value in options
            case value
            when Array
              for item in value
                data << "<#{key}>#{item}</#{key}>"
              end
            when Hash
              data << "<#{key}>"
              for inner_key, inner_value in value
                data << "<#{inner_key}>#{inner_value}</#{inner_key}>"
              end
              data << "</#{key}>"
            else
              data << "<#{key}>#{value}</#{key}>"
            end
          end
          data << "</StreamingDistributionConfig>"
          request({
            :body       => data,
            :expects    => 200,
            :headers    => {
              'Content-Type'  => 'text/xml',
              'If-Match'      => etag
            },
            :idempotent => true,
            :method     => 'PUT',
            :parser     => Fog::Parsers::AWS::CDN::StreamingDistribution.new,
            :path       => "/streaming-distribution/#{distribution_id}/config"
          })
        end
      end

      class Mock
        def put_streaming_distribution_config(distribution_id, etag, options = {})
          distribution = self.data[:streaming_distributions][distribution_id]

          if distribution
            if distribution['ETag'] != etag
              Fog::AWS::CDN::Mock.error(:invalid_if_match_version)
            end
            unless distribution['StreamingDistributionConfig']['CallerReference']
              Fog::AWS::CDN::Mock.error(:illegal_update)
            end

            distribution['StreamingDistributionConfig'].merge!(options)
            distribution['Status'] = 'InProgress'

            response = Excon::Response.new
            response.status = 200
            response.headers['ETag'] = Fog::AWS::CDN::Mock.generic_id
            response.body = distribution.merge({ 'LastModifiedTime' => Time.now.utc.iso8601 }).reject{ |k,v| k == 'ETag' }
            response
          else
            Fog::AWS::CDN::Mock.error(:no_such_streaming_distribution)
          end
        end
      end
    end
  end
end
