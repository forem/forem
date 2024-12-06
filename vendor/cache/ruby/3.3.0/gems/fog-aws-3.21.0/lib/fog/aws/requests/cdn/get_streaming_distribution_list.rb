module Fog
  module AWS
    class CDN
      class Real
        require 'fog/aws/parsers/cdn/get_streaming_distribution_list'

        # List information about distributions in CloudFront.
        #
        # @param options [Hash] Config arguments for list.
        # @option options Marker [String] Limits object keys to only those that appear lexicographically after its value.
        # @option options MaxItems [Integer] Limits number of object keys returned.
        #
        # @return [Excon::Response]
        #   * body [Hash]:
        #     * IsTruncated [Boolean] - Whether or not the listing is truncated.
        #     * Marker [String] - Marker specified for query.
        #     * MaxItems [Integer] - Maximum number of keys specified for query.
        #     * NextMarker [String] - Marker to specify for next page (id of last result of current page).
        #     * StreamingDistributionSummary [Array]:
        #       * S3Origin [Hash]:
        #         * DNSName [String] - Origin to associate with distribution, ie 'mybucket.s3.amazonaws.com'.
        #         * OriginAccessIdentity [String] - Optional: Used when serving private content.
        #       or
        #       * CustomOrigin [Hash]:
        #         * DNSName [String] - Origin to associate with distribution, ie 'www.example.com'.
        #         * HTTPPort [Integer] - HTTP port of origin, in [80, 443] or (1024...65535).
        #         * HTTPSPort [Integer] - HTTPS port of origin, in [80, 443] or (1024...65535).
        #       * OriginProtocolPolicy [String] - Policy on using http vs https, in ['http-only', 'match-viewer'].
        #       * Comment [String] - Comment associated with distribution.
        #       * CNAME [Array] - Array of associated cnames.
        #       * Enabled [Boolean] - Whether or not distribution is enabled.
        #       * Id [String] - Id of distribution.
        #       * LastModifiedTime [String] - Timestamp of last modification of distribution.
        #       * Origin [String] - S3 origin bucket.
        #       * Status [String] - Status of distribution.
        #       * TrustedSigners [Array] - Trusted signers.
        #
        # @see http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/ListStreamingDistributions.html

        def get_streaming_distribution_list(options = {})
          request({
            :expects    => 200,
            :idempotent => true,
            :method   => 'GET',
            :parser   => Fog::Parsers::AWS::CDN::GetStreamingDistributionList.new,
            :path       => "/streaming-distribution",
            :query      => options
          })
        end
      end

      class Mock
        def get_streaming_distribution_list(options = {})
          response = Excon::Response.new
          response.status = 200

          distributions = self.data[:streaming_distributions].values

          response.body = {
            'Marker' => Fog::Mock.random_hex(16),
            'IsTruncated' => false,
            'MaxItems' => 100,
            'StreamingDistributionSummary' => distributions.map { |d| to_streaming_distribution_summary(d) }
          }

          response
        end

        private

        def to_streaming_distribution_summary(d)
          {
            'DomainName' => d['DomainName'],
            'Id' => d['Id'],
            'LastModifiedTime' => d['LastModifiedTime']
          }.merge(d['StreamingDistributionConfig'])
        end
      end
    end
  end
end
