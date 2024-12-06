module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/describe_reserved_instances'

        # Describe all or specified reserved instances
        #
        # ==== Parameters
        # * filters<~Hash> - List of filters to limit results with
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - Id of request
        #     * 'reservedInstancesSet'<~Array>:
        #       * 'availabilityZone'<~String> - availability zone of the instance
        #       * 'duration'<~Integer> - duration of reservation, in seconds
        #       * 'fixedPrice'<~Float> - purchase price of reserved instance
        #       * 'instanceType'<~String> - type of instance
        #       * 'instanceCount'<~Integer> - number of reserved instances
        #       * 'productDescription'<~String> - reserved instance description
        #       * 'recurringCharges'<~Array>:
        #         * 'frequency'<~String> - frequency of a recurring charge while the reservation is active (only Hourly at this time)
        #         * 'amount'<~Float> - recurring charge amount
        #       * 'reservedInstancesId'<~String> - id of the instance
        #       * 'scope'<~String> - scope of the reservation (i.e. 'Availability Zone' or 'Region' - as of version 2016/11/15)
        #       * 'start'<~Time> - start time for reservation
        #       * 'state'<~String> - state of reserved instance purchase, in .[pending-payment, active, payment-failed, retired]
        #       * 'usagePrice"<~Float> - usage price of reserved instances, per hour
        #       * 'end'<~Time> - time reservation stopped being applied (i.e. sold or canceled - as of version 2013/10/01)
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeReservedInstances.html]
        def describe_reserved_instances(filters = {})
          unless filters.is_a?(Hash)
            Fog::Logger.deprecation("describe_reserved_instances with #{filters.class} param is deprecated, use describe_reserved_instances('reserved-instances-id' => []) instead [light_black](#{caller.first})[/]")
            filters = {'reserved-instances-id' => [*filters]}
          end
          params = Fog::AWS.indexed_filters(filters)
          request({
            'Action'    => 'DescribeReservedInstances',
            :idempotent => true,
            :parser     => Fog::Parsers::AWS::Compute::DescribeReservedInstances.new
          }.merge!(params))
        end
      end

      class Mock
        def describe_reserved_instances(filters = {})
          response = Excon::Response.new
          response.status = 200

          response.body = {
            'reservedInstancesSet' => self.data[:reserved_instances].values,
            'requestId' => Fog::AWS::Mock.request_id
          }

          response
        end
      end
    end
  end
end
