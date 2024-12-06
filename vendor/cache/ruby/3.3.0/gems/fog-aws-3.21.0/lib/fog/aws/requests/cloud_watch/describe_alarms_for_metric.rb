module Fog
  module AWS
    class CloudWatch
      class Real
        require 'fog/aws/parsers/cloud_watch/describe_alarms_for_metric'

        # Retrieves all alarms for a single metric
        # ==== Options
        # * Dimensions<~Array>: a list of dimensions to filter against
        #     Name : The name of the dimension
        #     Value : The value to filter against
        # * MetricName<~String>: The name of the metric
        # * Namespace<~String>: The namespace of the metric
        # * Period<~Integer>: The period in seconds over which the statistic is applied
        # * Statistics<~String>: The statistic for the metric
        # * Unit<~String> The unit for the metric
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AmazonCloudWatch/latest/APIReference/API_DescribeAlarms.html
        #

        def describe_alarms_for_metric(options)
          if dimensions = options.delete('Dimensions')
            options.merge!(AWS.indexed_param('Dimensions.member.%d.Name', dimensions.map {|dimension| dimension['Name']}))
            options.merge!(AWS.indexed_param('Dimensions.member.%d.Value', dimensions.map {|dimension| dimension['Value']}))
          end
          request({
              'Action'    => 'DescribeAlarmsForMetric',
              :parser     => Fog::Parsers::AWS::CloudWatch::DescribeAlarmsForMetric.new
            }.merge(options))
        end
      end
    end
  end
end
