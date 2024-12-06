module Fog
  module AWS
    class CloudWatch
      class MetricStatistic < Fog::Model
        attribute :label, :aliases => 'Label'
        attribute :minimum, :aliases => 'Minimum'
        attribute :maximum, :aliases => 'Maximum'
        attribute :sum, :aliases => 'Sum'
        attribute :average, :aliases => 'Average'
        attribute :sample_count, :aliases => 'SampleCount'
        attribute :timestamp, :aliases => 'Timestamp'
        attribute :unit, :aliases => 'Unit'
        attribute :metric_name, :aliases => 'MetricName'
        attribute :namespace, :aliases => 'Namespace'
        attribute :dimensions, :aliases => 'Dimensions'
        attribute :value

        def save
          requires :metric_name
          requires :namespace
          requires :unit

          put_opts = {'MetricName' => metric_name, 'Unit' => unit}
          put_opts.merge!('Dimensions' => dimensions) if dimensions
          if value
            put_opts.merge!('Value' => value)
          else
            put_opts.merge!('StatisticValues' => {
              'Minimum' => minimum,
              'Maximum' => maximum,
              'Sum' => sum,
              'Average' => average,
              'SampleCount' => sample_count
            })
          end
          service.put_metric_data(namespace, [put_opts])
          true
        end
      end
    end
  end
end
