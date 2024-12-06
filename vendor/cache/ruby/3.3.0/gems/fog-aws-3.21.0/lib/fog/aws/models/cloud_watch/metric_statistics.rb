require 'fog/aws/models/cloud_watch/metric_statistic'

module Fog
  module AWS
    class CloudWatch
      class MetricStatistics < Fog::Collection
        model Fog::AWS::CloudWatch::MetricStatistic

        def all(conditions)
          metricName = conditions['MetricName']
          namespace = conditions['Namespace']
          dimensions = conditions['Dimensions']
          get_metric_opts = {"StartTime" => (Time.now-3600).iso8601, "EndTime" => Time.now.iso8601, "Period" => 300}.merge(conditions)
          data = service.get_metric_statistics(get_metric_opts).body['GetMetricStatisticsResult']['Datapoints']
          data.map! { |datum| datum.merge('MetricName' => metricName, 'Namespace' => namespace, 'Dimensions' => dimensions) }
          load(data) # data is an array of attribute hashes
        end
      end
    end
  end
end
