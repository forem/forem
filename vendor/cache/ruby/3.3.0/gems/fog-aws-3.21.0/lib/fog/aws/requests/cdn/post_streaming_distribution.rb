module Fog
  module AWS
    class CDN
      class Real
        require 'fog/aws/parsers/cdn/streaming_distribution'

        # Create a new streaming distribution in CloudFront.
        #
        # @param options [Hash] Config for distribution.
        #
        #   REQUIRED:
        #   * S3Origin [Hash]:
        #     * DNSName [String] Origin to associate with distribution, ie 'mybucket.s3.amazonaws.com'.
        #   OPTIONAL:
        #   * CallerReference [String] Used to prevent replay, defaults to Time.now.to_i.to_s.
        #   * Comment [String] Optional comment about distribution.
        #   * CNAME [Array] Optional array of strings to set as CNAMEs.
        #   * Enabled [Boolean] Whether or not distribution should accept requests, defaults to true.
        #   * Logging [Hash]: Optional logging config.
        #     * Bucket [String] Bucket to store logs in, ie 'mylogs.s3.amazonaws.com'.
        #     * Prefix [String] Optional prefix for log filenames, ie 'myprefix/'.
        #
        # @return [Excon::Response]
        #   * body[Hash]:
        #     * Id [String] - Id of distribution.
        #     * Status'[String] - Status of distribution.
        #     * LastModifiedTime [String] - Timestamp of last modification of distribution.
        #     * DomainName [String] - Domain name of distribution.
        #     * StreamingDistributionConfig [Array]:
        #       * CallerReference [String] - Used to prevent replay, defaults to Time.now.to_i.to_s.
        #       * CNAME [Array] - Array of associated cnames.
        #       * Comment [String] - Comment associated with distribution.
        #       * Enabled [Boolean] - Whether or not distribution is enabled.
        #       * Logging [Hash]:
        #         * Bucket [String] - Bucket logs are stored in.
        #         * Prefix [String] - Prefix logs are stored with.
        #
        # @see http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/CreateStreamingDistribution.html

        def post_streaming_distribution(options = {})
          options['CallerReference'] = Time.now.to_i.to_s
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
            :expects    => 201,
            :headers    => { 'Content-Type' => 'text/xml' },
            :idempotent => true,
            :method     => 'POST',
            :parser     => Fog::Parsers::AWS::CDN::StreamingDistribution.new,
            :path       => "/streaming-distribution"
          })
        end
      end

      class Mock
        require 'time'

        def post_streaming_distribution(options = {})
          if self.data[:streaming_distributions].values.any? { |d| (d['CNAME'] & (options['CNAME']||[])).empty? }
            Fog::AWS::CDN::Mock.error(:invalid_argument, 'CNAME is already in use')
          end

          response = Excon::Response.new

          response.status = 201
          options['CallerReference'] = Time.now.to_i.to_s

          dist_id = Fog::AWS::CDN::Mock.distribution_id

          distribution = {
            'DomainName' => Fog::AWS::CDN::Mock.domain_name,
            'Id' => dist_id,
            'Status' => 'InProgress',
            'LastModifiedTime' => Time.now.utc.iso8601,
            'StreamingDistributionConfig' => {
              'CallerReference' => options['CallerReference'],
              'CNAME' => options['CNAME'] || [],
              'Comment' => options['Comment'],
              'Enabled' => options['Enabled'],
              'Logging' => {
                'Bucket' => options['Bucket'],
                'Prefix' => options['Prefix']
              },
              'S3Origin' => options['S3Origin'],
              'TrustedSigners' => options['TrustedSigners'] || []
            }
          }

          self.data[:streaming_distributions][dist_id] = distribution

          response.body = distribution
          response
        end
      end
    end
  end
end
