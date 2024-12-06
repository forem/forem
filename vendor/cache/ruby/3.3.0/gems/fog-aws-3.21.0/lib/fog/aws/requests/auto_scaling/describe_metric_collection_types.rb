module Fog
  module AWS
    class AutoScaling
      class Real
        require 'fog/aws/parsers/auto_scaling/describe_metric_collection_types'

        # Returns a list of metrics and a corresponding list of granularities
        # for each metric.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        #     * 'DescribeMetricCollectionTypesResult'<~Hash>:
        #       * 'Granularities'<~Array>:
        #         * 'Granularity'<~String> - The granularity of a Metric.
        #       * 'Metrics'<~Array>:
        #         * 'Metric'<~String> - The name of a Metric.
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_DescribeMetricCollectionTypes.html
        #
        def describe_metric_collection_types()
          request({
            'Action'    => 'DescribeMetricCollectionTypes',
            :idempotent => true,
            :parser     => Fog::Parsers::AWS::AutoScaling::DescribeMetricCollectionTypes.new
          })
        end
      end

      class Mock
        def describe_metric_collection_types()
          results = {
            'Granularities' => [],
            'Metrics' => []
          }
          self.data[:metric_collection_types][:granularities].each do |granularity|
            results['Granularities'] << { 'Granularity' => granularity }
          end
          self.data[:metric_collection_types][:metrics].each do |metric|
            results['Metrics'] << { 'Metric' => metric }
          end
          response = Excon::Response.new
          response.status = 200
          response.body = {
            'DescribeMetricCollectionTypesResult' => results,
            'ResponseMetadata' => { 'RequestId' => Fog::AWS::Mock.request_id }
          }
          response
        end
      end
    end
  end
end
