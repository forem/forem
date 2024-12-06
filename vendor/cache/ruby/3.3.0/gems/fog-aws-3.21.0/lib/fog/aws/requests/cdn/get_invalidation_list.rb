module Fog
  module AWS
    class CDN
      class Real
        require 'fog/aws/parsers/cdn/get_invalidation_list'

        # Get invalidation list.
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
        #     * InvalidationSummary [Array]:
        #       * Id [String]
        #       * Status [String]
        #
        # @see http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/ListInvalidation.html

        def get_invalidation_list(distribution_id, options = {})
          request({
            :expects    => 200,
            :idempotent => true,
            :method   => 'GET',
            :parser   => Fog::Parsers::AWS::CDN::GetInvalidationList.new,
            :path       => "/distribution/#{distribution_id}/invalidation",
            :query      => options
          })
        end
      end

      class Mock
        def get_invalidation_list(distribution_id, options = {})
          distribution = self.data[:distributions][distribution_id]
          unless distribution
            Fog::AWS::CDN::Mock.error(:no_such_distribution)
          end

          invalidations = (self.data[:invalidations][distribution_id] || {}).values

          invalidations.each do |invalidation|
            if invalidation['Status'] == 'InProgress' && (Time.now - Time.parse(invalidation['CreateTime']) >= Fog::Mock.delay * 2)
              invalidation['Status'] = 'Completed'
              distribution['InProgressInvalidationBatches'] -= 1
            end
          end

          response = Excon::Response.new
          response.status = 200

          response.body = {
            'Marker' => Fog::Mock.random_hex(16),
            'IsTruncated' => false,
            'MaxItems' => 100,
            'InvalidationSummary' => invalidations.map { |i| to_invalidation_summary(i) }
          }
          response
        end

        private

        def to_invalidation_summary(d)
          {
            'Id' => d['Id'],
            'Status' => d['Status']
          }
        end
      end
    end
  end
end
