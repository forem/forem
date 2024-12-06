require 'fog/aws/models/cloud_watch/alarm_datum'

module Fog
  module AWS
    class CloudWatch
      class AlarmData < Fog::Collection
        model Fog::AWS::CloudWatch::AlarmDatum

        def all(conditions={})
          data = service.describe_alarms(conditions).body['DescribeAlarmsResult']['MetricAlarms']
          load(data) # data is an array of attribute hashes
        end

        def get(namespace, metric_name, dimensions=nil, period=nil, statistic=nil, unit=nil)
          list_opts = {'Namespace' => namespace, 'MetricName' => metric_name}
          if dimensions
            dimensions_array = dimensions.map do |name, value|
              {'Name' => name, 'Value' => value}
            end
            list_opts.merge!('Dimensions' => dimensions_array)
          end
          if period
            list_opts.merge!('Period' => period)
          end
          if statistic
          list_opts.merge!('Statistic' => statistic)
          end
          if unit
            list_opts.merge!('Unit' => unit)
          end
          data = service.describe_alarms_for_metric(list_opts).body['DescribeAlarmsForMetricResult']['MetricAlarms']
          load(data)
        end
      end
    end
  end
end
