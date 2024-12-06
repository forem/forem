module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/describe_spot_price_history'

        # Describe all or specified spot price history
        #
        # ==== Parameters
        # * filters<~Hash> - List of filters to limit results with
        #   * filters and/or the following
        #     * 'AvailabilityZone'<~String> - availability zone of offering
        #     * 'InstanceType'<~Array> - instance types of offering
        #     * 'ProductDescription'<~Array> - basic product descriptions
        #     * 'StartTime'<~Time> - The date and time, up to the past 90 days, from which to start retrieving the price history data
        #     * 'EndTime'<~Time> - The date and time, up to the current date, from which to stop retrieving the price history data
        #     * 'MaxResults'<~Integer> - The maximum number of results to return for the request in a single page
        #     * 'NextToken'<~String> - The token to retrieve the next page of results
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - Id of request
        #     * 'spotPriceHistorySet'<~Array>:
        #       * 'availabilityZone'<~String> - availability zone for instance
        #       * 'instanceType'<~String> - the type of instance
        #       * 'productDescription'<~String> - general description of AMI
        #       * 'spotPrice'<~Float> - maximum price to launch one or more instances
        #       * 'timestamp'<~Time> - date and time of request creation
        #     * 'nextToken'<~String> - token to retrieve the next page of results
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeSpotPriceHistory.html]
        def describe_spot_price_history(filters = {})
          params = {}

          for key in %w(AvailabilityZone StartTime EndTime MaxResults NextToken)
            if filters.is_a?(Hash) && filters.key?(key)
              params[key] = filters.delete(key)
            end
          end

          if instance_types = filters.delete('InstanceType')
            params.merge!(Fog::AWS.indexed_param('InstanceType', [*instance_types]))
          end

          if product_descriptions = filters.delete('ProductDescription')
            params.merge!(Fog::AWS.indexed_param('ProductDescription', [*product_descriptions]))
          end

          params.merge!(Fog::AWS.indexed_filters(filters))

          request({
            'Action'    => 'DescribeSpotPriceHistory',
            :idempotent => true,
            :parser     => Fog::Parsers::AWS::Compute::DescribeSpotPriceHistory.new
          }.merge!(params))
        end
      end

      class Mock
        def describe_spot_price_history(filters = {})
          params = {}
          spot_price_history_set = []

          response = Excon::Response.new
          response.status = 200

          for key in %w(StartTime EndTime NextToken)
            if filters.is_a?(Hash) && filters.key?(key)
              Fog::Logger.warning("#{key} filters are not yet mocked [light_black](#{caller.first})[/]")
              Fog::Mock.not_implemented
            end
          end

          for key in %w(AvailabilityZone MaxResults)
            if filters.is_a?(Hash) && filters.key?(key)
              params[key] = filters.delete(key)
            end
          end

          all_zones = describe_availability_zones.body['availabilityZoneInfo'].map { |z| z['zoneName'] }
          zones = params['AvailabilityZone']
          if (!zones.nil? && !all_zones.include?([*zones].shuffle.first))
            az_error = "InvalidParameterValue => Invalid availability zone: [#{zones}]"
            raise Fog::AWS::Compute::Error, az_error
          end
          zones = all_zones if zones.nil?

          max_results = params['MaxResults'] || Fog::Mock.random_numbers(3).to_i
          if !(max_results.is_a?(Integer) && max_results > 0)
            max_results_error = "InvalidParameterValue => Invalid value '#{max_results}' for maxResults"
            raise Fog::AWS::Compute::Error, max_results_error
          end

          all_instance_types = flavors.map { |f| f.id }
          instance_types = filters.delete('InstanceType') || all_instance_types
          product_descriptions = filters.delete('ProductDescription') || Fog::AWS::Mock.spot_product_descriptions

          max_results.times do
            spot_price_history_set << {
              'instanceType'       => [*instance_types].shuffle.first,
              'productDescription' => [*product_descriptions].shuffle.first,
              'spotPrice'          => ((rand + [0 , 1].shuffle.first) * 10000).round / 10000.0,
              'timestamp'          => Time.now - (1 + rand(86400)),
              'availabilityZone'   => [*zones].shuffle.first
            }
          end
          spot_price_history_set.sort! { |x,y| x['timestamp'] <=> y['timestamp'] }

          response.body = {
            'spotPriceHistorySet' => spot_price_history_set,
            'requestId'           => Fog::AWS::Mock.request_id,
            'nextToken'           => nil
          }
          response
        end
      end
    end
  end
end
