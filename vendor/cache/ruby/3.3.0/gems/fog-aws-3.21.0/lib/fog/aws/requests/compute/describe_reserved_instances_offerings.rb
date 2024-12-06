module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/describe_reserved_instances_offerings'

        # Describe all or specified reserved instances offerings
        #
        # ==== Parameters
        # * filters<~Hash> - List of filters to limit results with
        #   * filters and/or the following
        #     * 'AvailabilityZone'<~String> - availability zone of offering
        #     * 'InstanceType'<~String> - instance type of offering
        #     * 'InstanceTenancy'<~String> - tenancy of offering in ['default', 'dedicated']
        #     * 'OfferingType'<~String> - type of offering, in ['Heavy Utilization', 'Medium Utilization', 'Light Utilization']
        #     * 'ProductDescription'<~String> - description of offering, in ['Linux/UNIX', 'Linux/UNIX (Amazon VPC)', 'Windows', 'Windows (Amazon VPC)']
        #     * 'MaxDuration'<~Integer> - maximum duration (in seconds) of offering
        #     * 'MinDuration'<~Integer> - minimum duration (in seconds) of offering
        #     * 'MaxResults'<~Integer> - The maximum number of results to return for the request in a single page
        #     * 'NextToken'<~String> - The token to retrieve the next page of results
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - Id of request
        #     * 'reservedInstancesOfferingsSet'<~Array>:
        #       * 'availabilityZone'<~String> - availability zone of offering
        #       * 'duration'<~Integer> - duration, in seconds, of offering
        #       * 'fixedPrice'<~Float> - purchase price of offering
        #       * 'includeMarketplace'<~Boolean> - whether or not to include marketplace offerings
        #       * 'instanceType'<~String> - instance type of offering
        #       * 'offeringType'<~String> - type of offering, in ['Heavy Utilization', 'Medium Utilization', 'Light Utilization']
        #       * 'productDescription'<~String> - description of offering
        #       * 'reservedInstancesOfferingId'<~String> - id of offering
        #       * 'usagePrice'<~Float> - usage price of offering, per hour
        #     * 'NextToken'<~String> - The token to retrieve the next page of results
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeReservedInstancesOfferings.html]
        def describe_reserved_instances_offerings(filters = {})
          options = {}
          for key in %w(AvailabilityZone InstanceType InstanceTenancy OfferingType ProductDescription MaxDuration MinDuration MaxResults NextToken)
            if filters.is_a?(Hash) && filters.key?(key)
              options[key] = filters.delete(key)
            end
          end
          params = Fog::AWS.indexed_filters(filters).merge!(options)
          request({
            'Action'    => 'DescribeReservedInstancesOfferings',
            :idempotent => true,
            :parser     => Fog::Parsers::AWS::Compute::DescribeReservedInstancesOfferings.new
          }.merge!(params))
        end
      end

      class Mock
        def describe_reserved_instances_offerings(filters = {})
          response = Excon::Response.new
          response.status = 200

          self.data[:reserved_instances_offerings] ||= [{
            'reservedInstancesOfferingId' => Fog::AWS::Mock.reserved_instances_offering_id,
            'instanceType'                => 'm1.small',
            'availabilityZone'            => 'us-east-1d',
            'duration'                    => 31536000,
            'fixedPrice'                  => 350.0,
            'offeringType'                => 'Medium Utilization',
            'usagePrice'                  => 0.03,
            'productDescription'          => 'Linux/UNIX',
            'instanceTenancy'             => 'default',
            'currencyCode'                => 'USD'
          }]

          response.body = {
            'reservedInstancesOfferingsSet' => self.data[:reserved_instances_offerings],
            'requestId' => Fog::AWS::Mock.request_id,
            'nextToken' => (0...64).map { ('a'..'z').to_a[rand(26)] }.join
          }

          response
        end
      end
    end
  end
end
