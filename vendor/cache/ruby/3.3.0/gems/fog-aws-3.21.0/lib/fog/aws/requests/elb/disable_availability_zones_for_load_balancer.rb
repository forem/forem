module Fog
  module AWS
    class ELB
      class Real
        require 'fog/aws/parsers/elb/disable_availability_zones_for_load_balancer'

        # Disable an availability zone for an existing ELB
        #
        # ==== Parameters
        # * availability_zones<~Array> - List of availability zones to disable on ELB
        # * lb_name<~String> - Load balancer to disable availability zones on
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        #     * 'DisableAvailabilityZonesForLoadBalancerResult'<~Hash>:
        #       * 'AvailabilityZones'<~Array> - A list of updated Availability Zones for the LoadBalancer.
        def disable_availability_zones_for_load_balancer(availability_zones, lb_name)
          params = Fog::AWS.indexed_param('AvailabilityZones.member', [*availability_zones])
          request({
            'Action'           => 'DisableAvailabilityZonesForLoadBalancer',
            'LoadBalancerName' => lb_name,
            :parser            => Fog::Parsers::AWS::ELB::DisableAvailabilityZonesForLoadBalancer.new
          }.merge!(params))
        end

        alias_method :disable_zones, :disable_availability_zones_for_load_balancer
      end

      class Mock
        def disable_availability_zones_for_load_balancer(availability_zones, lb_name)
          raise Fog::AWS::ELB::NotFound unless load_balancer = self.data[:load_balancers][lb_name]

          response = Excon::Response.new
          response.status = 200

          load_balancer['AvailabilityZones'].delete_if { |az| availability_zones.include? az }

          response.body = {
            'ResponseMetadata' => {
              'RequestId' => Fog::AWS::Mock.request_id
            },
            'DisableAvailabilityZonesForLoadBalancerResult' => {
              'AvailabilityZones' => load_balancer['AvailabilityZones']
            }
          }

          response
        end

        alias_method :disable_zones, :disable_availability_zones_for_load_balancer
      end
    end
  end
end
