module Fog
  module AWS
    class CDN
      class Real
        # Delete a distribution from CloudFront.
        #
        # @param distribution_id [String] Id of distribution to delete.
        # @param etag [String] etag of that distribution from earlier get or put
        #
        # @see http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/DeleteDistribution.html

        def delete_distribution(distribution_id, etag)
          request({
            :expects    => 204,
            :headers    => { 'If-Match' => etag },
            :idempotent => true,
            :method     => 'DELETE',
            :path       => "/distribution/#{distribution_id}"
          })
        end
      end

      class Mock
        def delete_distribution(distribution_id, etag)
          distribution = self.data[:distributions][distribution_id]

          if distribution
            if distribution['ETag'] != etag
              Fog::AWS::CDN::Mock.error(:invalid_if_match_version)
            end
            unless distribution['DistributionConfig']['CallerReference']
              Fog::AWS::CDN::Mock.error(:illegal_update)
            end
            if distribution['DistributionConfig']['Enabled']
              Fog::AWS::CDN::Mock.error(:distribution_not_disabled)
            end

            self.data[:distributions].delete(distribution_id)
            self.data[:invalidations].delete(distribution_id)

            response = Excon::Response.new
            response.status = 204
            response.body = "x-amz-request-id: #{Fog::AWS::Mock.request_id}"
            response
          else
            Fog::AWS::CDN::Mock.error(:no_such_distribution)
          end
        end
      end
    end
  end
end
