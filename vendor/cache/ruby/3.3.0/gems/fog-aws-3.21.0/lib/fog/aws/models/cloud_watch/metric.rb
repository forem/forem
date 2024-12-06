module Fog
  module AWS
    class CloudWatch
      class Metric < Fog::Model
        attribute :name, :aliases => 'MetricName'
        attribute :namespace, :aliases => 'Namespace'
        attribute :dimensions, :aliases => 'Dimensions'
      end
    end
  end
end
