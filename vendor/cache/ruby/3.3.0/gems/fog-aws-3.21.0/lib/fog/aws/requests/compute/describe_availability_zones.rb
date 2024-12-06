module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/describe_availability_zones'

        # Describe all or specified availability zones
        #
        # ==== Params
        # * filters<~Hash> - List of filters to limit results with
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - Id of request
        #     * 'availabilityZoneInfo'<~Array>:
        #       * 'regionName'<~String> - Name of region
        #       * 'zoneName'<~String> - Name of zone
        #       * 'zoneState'<~String> - State of zone
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeAvailabilityZones.html]
        def describe_availability_zones(filters = {})
          unless filters.is_a?(Hash)
            Fog::Logger.deprecation("describe_availability_zones with #{filters.class} param is deprecated, use describe_availability_zones('zone-name' => []) instead [light_black](#{caller.first})[/]")
            filters = {'zone-name' => [*filters]}
          end
          params = Fog::AWS.indexed_filters(filters)
          request({
            'Action'    => 'DescribeAvailabilityZones',
            :idempotent => true,
            :parser     => Fog::Parsers::AWS::Compute::DescribeAvailabilityZones.new
          }.merge!(params))
        end
      end

      class Mock
        def describe_availability_zones(filters = {})
          unless filters.is_a?(Hash)
            Fog::Logger.deprecation("describe_availability_zones with #{filters.class} param is deprecated, use describe_availability_zones('zone-name' => []) instead [light_black](#{caller.first})[/]")
            filters = {'zone-name' => [*filters]}
          end

          response = Excon::Response.new

          all_zones = [
            {"messageSet" => [], "regionName" => "us-east-1", "zoneName" => "us-east-1a", "zoneState" => "available"},
            {"messageSet" => [], "regionName" => "us-east-1", "zoneName" => "us-east-1b", "zoneState" => "available"},
            {"messageSet" => [], "regionName" => "us-east-1", "zoneName" => "us-east-1c", "zoneState" => "available"},
            {"messageSet" => [], "regionName" => "us-east-1", "zoneName" => "us-east-1d", "zoneState" => "available"},
            {"messageSet" => [], "regionName" => "us-east-1", "zoneName" => "us-east-1e", "zoneState" => "available"},

            {"messageSet" => [], "regionName" => "us-east-2", "zoneName" => "us-east-2a", "zoneState" => "available"},
            {"messageSet" => [], "regionName" => "us-east-2", "zoneName" => "us-east-2b", "zoneState" => "available"},
            {"messageSet" => [], "regionName" => "us-east-2", "zoneName" => "us-east-2c", "zoneState" => "available"},

            {"messageSet" => [], "regionName" => "us-west-1", "zoneName" => "us-west-1a", "zoneState" => "available"},
            {"messageSet" => [], "regionName" => "us-west-1", "zoneName" => "us-west-1b", "zoneState" => "available"},
            {"messageSet" => [], "regionName" => "us-west-1", "zoneName" => "us-west-1c", "zoneState" => "available"},

            {"messageSet" => [], "regionName" => "us-west-2", "zoneName" => "us-west-2a", "zoneState" => "available"},
            {"messageSet" => [], "regionName" => "us-west-2", "zoneName" => "us-west-2b", "zoneState" => "available"},

            {"messageSet" => [], "regionName" => "sa-east-1", "zoneName" => "sa-east-1a", "zoneState" => "available"},
            {"messageSet" => [], "regionName" => "sa-east-1", "zoneName" => "sa-east-1b", "zoneState" => "available"},

            {"messageSet" => [], "regionName" => "eu-west-1", "zoneName" => "eu-west-1a", "zoneState" => "available"},
            {"messageSet" => [], "regionName" => "eu-west-1", "zoneName" => "eu-west-1b", "zoneState" => "available"},
            {"messageSet" => [], "regionName" => "eu-west-1", "zoneName" => "eu-west-1c", "zoneState" => "available"},

            {"messageSet" => [], "regionName" => "eu-west-2", "zoneName" => "eu-west-2a", "zoneState" => "available"},
            {"messageSet" => [], "regionName" => "eu-west-2", "zoneName" => "eu-west-2b", "zoneState" => "available"},

            {"messageSet" => [], "regionName" => "eu-west-3", "zoneName" => "eu-west-3a", "zoneState" => "available"},
            {"messageSet" => [], "regionName" => "eu-west-3", "zoneName" => "eu-west-3b", "zoneState" => "available"},

            {"messageSet" => [], "regionName" => "eu-central-1", "zoneName" => "eu-central-1a", "zoneState" => "available"},
            {"messageSet" => [], "regionName" => "eu-central-1", "zoneName" => "eu-central-1b", "zoneState" => "available"},

            {"messageSet" => [], "regionName" => "ca-central-1", "zoneName" => "ca-central-1a", "zoneState" => "available"},
            {"messageSet" => [], "regionName" => "ca-central-1", "zoneName" => "ca-central-1b", "zoneState" => "available"},

            {"messageSet" => [], "regionName" => "ap-northeast-1", "zoneName" => "ap-northeast-1a", "zoneState" => "available"},
            {"messageSet" => [], "regionName" => "ap-northeast-1", "zoneName" => "ap-northeast-1b", "zoneState" => "available"},

            {"messageSet" => [], "regionName" => "ap-northeast-2", "zoneName" => "ap-northeast-2a", "zoneState" => "available"},
            {"messageSet" => [], "regionName" => "ap-northeast-2", "zoneName" => "ap-northeast-2b", "zoneState" => "available"},

            {"messageSet" => [], "regionName" => "ap-southeast-1", "zoneName" => "ap-southeast-1a", "zoneState" => "available"},
            {"messageSet" => [], "regionName" => "ap-southeast-1", "zoneName" => "ap-southeast-1b", "zoneState" => "available"},

            {"messageSet" => [], "regionName" => "ap-southeast-2", "zoneName" => "ap-southeast-2a", "zoneState" => "available"},
            {"messageSet" => [], "regionName" => "ap-southeast-2", "zoneName" => "ap-southeast-2b", "zoneState" => "available"},

            {"messageSet" => [], "regionName" => "ap-south-1", "zoneName" => "ap-south-1a", "zoneState" => "available"},
            {"messageSet" => [], "regionName" => "ap-south-1", "zoneName" => "ap-south-1b", "zoneState" => "available"},
          ]

          availability_zone_info = all_zones.select { |zoneinfo| zoneinfo["regionName"] == @region }

          aliases = {'region-name' => 'regionName', 'zone-name' => 'zoneName', 'state' => 'zoneState'}
          for filter_key, filter_value in filters
            aliased_key = aliases[filter_key]
            availability_zone_info = availability_zone_info.reject{|availability_zone| ![*filter_value].include?(availability_zone[aliased_key])}
          end

          response.status = 200
          response.body = {
            'availabilityZoneInfo'  => availability_zone_info,
            'requestId'             => Fog::AWS::Mock.request_id
          }
          response
        end
      end
    end
  end
end
