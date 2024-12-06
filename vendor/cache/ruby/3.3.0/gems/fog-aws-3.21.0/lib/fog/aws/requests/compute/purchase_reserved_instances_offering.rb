module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/purchase_reserved_instances_offering'

        # Purchases a Reserved Instance for use with your account.
        #
        # ==== Parameters
        # * reserved_instances_offering_id<~String> - ID of the Reserved Instance offering you want to purchase.
        # * instance_count<~Integer> - The number of Reserved Instances to purchase.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - Id of request
        #     * 'reservedInstancesId'<~String> - Id of the purchased reserved instances.
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-PurchaseReservedInstancesOffering.html]
        def purchase_reserved_instances_offering(reserved_instances_offering_id, instance_count = 1)
          request({
            'Action'                      => 'PurchaseReservedInstancesOffering',
            'ReservedInstancesOfferingId' => reserved_instances_offering_id,
            'InstanceCount'               => instance_count,
            :idempotent                   => true,
            :parser                       => Fog::Parsers::AWS::Compute::PurchaseReservedInstancesOffering.new
          })
        end
      end

      class Mock
        def purchase_reserved_instances_offering(reserved_instances_offering_id, instance_count = 1)
          response = Excon::Response.new
          response.status = 200

          # Need to implement filters in the mock to find this there instead of here
          # Also there's no information about what to do when the specified reserved_instances_offering_id doesn't exist
          raise unless reserved_instance_offering = describe_reserved_instances_offerings.body["reservedInstancesOfferingsSet"].find { |offering| offering["reservedInstancesOfferingId"] == reserved_instances_offering_id }

          reserved_instances_id = Fog::AWS::Mock.reserved_instances_id
          reserved_instance_offering.delete('reservedInstancesOfferingId')

          self.data[:reserved_instances][reserved_instances_id] = reserved_instance_offering.merge({
            'reservedInstancesId' => reserved_instances_id,
            'start'               => Time.now,
            'end'                 => Time.now,
            'instanceCount'       => instance_count,
            'state'               => 'payment-pending',
            'tagSet'              => []
          })

          response.body = {
            'reservedInstancesId' => reserved_instances_id,
            'requestId' => Fog::AWS::Mock.request_id
          }

          response
        end
      end
    end
  end
end
