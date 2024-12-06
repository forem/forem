module Fog
  module AWS
    class CloudWatch
      class Real
        require 'fog/aws/parsers/cloud_watch/list_metrics'

        # List availabe metrics
        #
        # ==== Options
        # * Dimensions<~Array>: a list of dimensions to filter against,
        #     Name : The name of the dimension
        #     Value : The value to filter against
        # * MetricName<~String>: The name of the metric to filter against
        # * Namespace<~String>: The namespace to filter against
        # * NextToken<~String> The token returned by a previous call to indicate that there is more data available
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AmazonCloudWatch/latest/APIReference/API_ListMetrics.html
        #
        def list_metrics(options={})
          if dimensions = options.delete('Dimensions')
            options.merge!(AWS.indexed_param('Dimensions.member.%d.Name', dimensions.map {|dimension| dimension['Name']}))
            options.merge!(AWS.indexed_param('Dimensions.member.%d.Value', dimensions.map {|dimension| dimension['Value']}))
          end

          request({
              'Action'    => 'ListMetrics',
              :parser     => Fog::Parsers::AWS::CloudWatch::ListMetrics.new
            }.merge(options))
        end
      end

      class Mock
        def list_metrics(options={})
          body = case options["NextToken"]
                 when nil
                   { "ListMetricsResult" => {
                      "Metrics" => (0...500).map{ {} },
                      "NextToken" => '1'
                   }}
                 when "1"
                   { "ListMetricsResult" => {
                      "Metrics" => (0...500).map{ {} },
                      "NextToken" => '2'
                   }}
                 when "2"
                   { "ListMetricsResult" => {
                      "Metrics" => (0...1).map{ {} }
                   }}
                 end

          Excon::Response.new.tap do |response|
            response.body = body
            response.status = 200
          end
        end
      end
    end
  end
end
