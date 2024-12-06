module Fog
  module AWS
    class CDN
      class Real
        require 'fog/aws/parsers/cdn/get_invalidation'

        # Get invalidation.
        #
        # @param distribution_id [String] Distribution id.
        # @param invalidation_id [String] Invalidation id.
        #
        # @return [Excon::Response]
        #   * body [Hash]:
        #     * Id [String] - Invalidation id.
        #     * Status [String]
        #     * CreateTime [String]
        #     * InvalidationBatch [Array]:
        #       * Path [String]
        #
        # @see http://docs.amazonwebservices.com/AmazonCloudFront/2010-11-01/APIReference/GetInvalidation.html

        def get_invalidation(distribution_id, invalidation_id)
          request({
            :expects    => 200,
            :idempotent => true,
            :method   => 'GET',
            :parser   => Fog::Parsers::AWS::CDN::GetInvalidation.new,
            :path       => "/distribution/#{distribution_id}/invalidation/#{invalidation_id}"
          })
        end
      end

      class Mock
        def get_invalidation(distribution_id, invalidation_id)
          distribution = self.data[:distributions][distribution_id]
          unless distribution
            Fog::AWS::CDN::Mock.error(:no_such_distribution)
          end

          invalidation = self.data[:invalidations][distribution_id][invalidation_id]
          unless invalidation
            Fog::AWS::CDN::Mock.error(:no_such_invalidation)
          end

          if invalidation['Status'] == 'InProgress' && (Time.now - Time.parse(invalidation['CreateTime']) >= Fog::Mock.delay * 2)
            invalidation['Status'] = 'Completed'
            distribution['InProgressInvalidationBatches'] -= 1
          end

          response = Excon::Response.new
          response.status = 200
          response.body = invalidation
          response
        end
      end
    end
  end
end
