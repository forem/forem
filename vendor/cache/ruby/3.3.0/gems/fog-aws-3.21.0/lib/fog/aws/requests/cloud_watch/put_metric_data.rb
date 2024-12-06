module Fog
  module AWS
    class CloudWatch
      class Real
        require 'fog/aws/parsers/cloud_watch/put_metric_data'

        # Publishes one or more data points to CloudWatch. A new metric is created if necessary
        # ==== Options
        # * Namespace<~String>: the namespace of the metric data
        # * MetricData<~Array>: the datapoints to publish of the metric
        #     * MetricName<~String>: the name of the metric
        #     * Timestamp<~String>: the timestamp for the data point. If omitted defaults to the time at which the data is received by CloudWatch
        #     * Unit<~String>: the unit
        #     * Value<~Double> the value for the metric
        #     * StatisticValues<~Hash>:
        #         * Maximum<~Double>: the maximum value of the sample set
        #         * Sum<~Double>: the sum of the values of the sample set
        #         * SampleCount<~Double>: the number of samples used for the statistic set
        #         * Minimum<~Double>: the minimum value of the sample set
        #     * Dimensions<~Array>: the dimensions for the metric. From 0 to 10 may be included
        #          * Name<~String>
        #         * Value<~String>
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AmazonCloudWatch/latest/APIReference/API_PutMetricData.html
        #

        def put_metric_data(namespace, metric_data)
          options = {'Namespace' => namespace}

          #first index the dimensions for any of the datums that have dimensions
          metric_data.map! do |metric_datum|
            if dimensions = metric_datum.delete('Dimensions')
              metric_datum.merge!(AWS.indexed_param('Dimensions.member.%d.Name', dimensions.map {|dimension| dimension['Name']}))
              metric_datum.merge!(AWS.indexed_param('Dimensions.member.%d.Value', dimensions.map {|dimension| dimension['Value']}))
            end
            metric_datum
          end
          #then flatten out an hashes in the metric_data array
          metric_data.map! { |metric_datum| flatten_hash(metric_datum) }
          #then index the metric_data array
          options.merge!(AWS.indexed_param('MetricData.member.%d', [*metric_data]))
          #then finally flatten out an hashes in the overall options array
          options = flatten_hash(options)

          request({
              'Action'    => 'PutMetricData',
              :parser     => Fog::Parsers::AWS::CloudWatch::PutMetricData.new
            }.merge(options))
        end
        private

        def flatten_hash(starting)
          finishing = {}
          starting.each do |top_level_key, top_level_value|
            if top_level_value.is_a?(Hash)
              nested_hash = top_level_value
              nested_hash.each do |nested_key, nested_value|
                finishing["#{top_level_key}.#{nested_key}"] = nested_value
              end
            else
              finishing[top_level_key] = top_level_value
            end
          end
          return finishing
        end
      end
    end
  end
end
