require 'fog/aws/models/cloud_watch/metric'

module Fog
  module AWS
    class CloudWatch
      class Metrics < Fog::Collection
        attribute :next_token, :aliases => 'NextToken'

        model Fog::AWS::CloudWatch::Metric

        def all(conditions={})
          result = service.list_metrics(conditions).body['ListMetricsResult']
          merge_attributes("NextToken" => result["NextToken"])
          load(result['Metrics']) # an array of attribute hashes
        end

        alias_method :each_metric_this_page, :each
        def each
          if !block_given?
            self
          else
            subset = dup.all
            subset.each_metric_this_page {|m| yield m }

            while next_token = subset.next_token
              subset = subset.all("NextToken" => next_token)
              subset.each_metric_this_page {|m| yield m }
            end

            self
          end
        end

        def get(namespace, metric_name, dimensions=nil)
          list_opts = {'Namespace' => namespace, 'MetricName' => metric_name}
          if dimensions
            dimensions_array = dimensions.map do |name, value|
              {'Name' => name, 'Value' => value}
            end
            # list_opts.merge!('Dimensions' => dimensions_array)
          end
          if data = service.list_metrics(list_opts).body['ListMetricsResult']['Metrics'].first
            new(data)
          end
        end
      end
    end
  end
end
