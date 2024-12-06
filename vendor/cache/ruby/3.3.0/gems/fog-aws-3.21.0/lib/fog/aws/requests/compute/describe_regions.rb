module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/describe_regions'

        # Describe all or specified regions
        #
        # ==== Params
        # * filters<~Hash> - List of filters to limit results with
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - Id of request
        #     * 'regionInfo'<~Array>:
        #       * 'regionName'<~String> - Name of region
        #       * 'regionEndpoint'<~String> - Service endpoint for region
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeRegions.html]
        def describe_regions(filters = {})
          unless filters.is_a?(Hash)
            Fog::Logger.deprecation("describe_regions with #{filters.class} param is deprecated, use describe_regions('region-name' => []) instead [light_black](#{caller.first})[/]")
            filters = {'region-name' => [*filters]}
          end
          params = Fog::AWS.indexed_filters(filters)
          request({
            'Action'    => 'DescribeRegions',
            :idempotent => true,
            :parser     => Fog::Parsers::AWS::Compute::DescribeRegions.new
          }.merge!(params))
        end
      end

      class Mock
        def describe_regions(filters = {})
          unless filters.is_a?(Hash)
            Fog::Logger.deprecation("describe_regions with #{filters.class} param is deprecated, use describe_regions('region-name' => []) instead [light_black](#{caller.first})[/]")
            filters = {'region-name' => [*filters]}
          end

          response = Excon::Response.new
          region_info = [
            {"regionName"=>"eu-west-1", "regionEndpoint"=>"eu-west-1.ec2.amazonaws.com"},
            {"regionName"=>"us-east-1", "regionEndpoint"=>"us-east-1.ec2.amazonaws.com"}
          ]

          aliases = {'region-name' => 'regionName', 'endpoint' => 'regionEndpoint'}
          for filter_key, filter_value in filters
            aliased_key = aliases[filter_key]
            region_info = region_info.reject{|region| ![*filter_value].include?(region[aliased_key])}
          end

          response.status = 200
          response.body = {
            'requestId'   => Fog::AWS::Mock.request_id,
            'regionInfo'  => region_info
          }
          response
        end
      end
    end
  end
end
