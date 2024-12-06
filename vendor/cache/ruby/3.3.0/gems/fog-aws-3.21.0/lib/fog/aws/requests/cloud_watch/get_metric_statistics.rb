module Fog
  module AWS
    class CloudWatch
      class Real
        require 'fog/aws/parsers/cloud_watch/get_metric_statistics'

        # Fetch datapoints for a metric. At most 1440 datapoints will be returned, the most datapoints that can be queried is 50850
        # StartTime is capped to 2 weeks ago
        # ==== Options
        # * Namespace<~String>: the namespace of the metric
        # * MetricName<~String>: the name of the metric
        # * StartTime<~Datetime>: when to start fetching datapoints from (inclusive)
        # * EndTime<~Datetime>: used to determine the last datapoint to fetch (exclusive)
        # * Period<~Integer>: Granularity, in seconds of the returned datapoints. Must be a multiple of 60, and at least 60
        # * Statistics<~Array>: An array of up to 5 strings, which name the statistics to return
        # * Unit<~String>: The unit for the metric
        # * Dimensions<~Array>: a list of dimensions to filter against (optional)
        #     Name : The name of the dimension
        #     Value : The value to filter against
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AmazonCloudWatch/latest/APIReference/API_GetMetricStatistics.html
        #
        def get_metric_statistics(options={})
          %w{Statistics StartTime EndTime Period MetricName Namespace}.each do |required_parameter|
            raise ArgumentError, "Must provide #{required_parameter}" unless options.key?(required_parameter)
          end
          statistics = options.delete 'Statistics'
          options.merge!(AWS.indexed_param('Statistics.member.%d', [*statistics]))

          if dimensions = options.delete('Dimensions')
            options.merge!(AWS.indexed_param('Dimensions.member.%d.Name', dimensions.map {|dimension| dimension['Name']}))
            options.merge!(AWS.indexed_param('Dimensions.member.%d.Value', dimensions.map {|dimension| dimension['Value']}))
          end

          request({
              'Action'    => 'GetMetricStatistics',
              :parser     => Fog::Parsers::AWS::CloudWatch::GetMetricStatistics.new
            }.merge(options))
        end
      end
    end
  end
end
