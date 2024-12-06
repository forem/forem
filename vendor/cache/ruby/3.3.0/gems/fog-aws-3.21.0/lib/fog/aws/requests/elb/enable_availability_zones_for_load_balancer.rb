module Fog
  module AWS
    class ELB
      class Real
        require 'fog/aws/parsers/elb/enable_availability_zones_for_load_balancer'

        # Enable an availability zone for an existing ELB
        #
        # ==== Parameters
        # * availability_zones<~Array> - List of availability zones to enable on ELB
        # * lb_name<~String> - Load balancer to enable availability zones on
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        #     * 'EnableAvailabilityZonesForLoadBalancerResult'<~Hash>:
        #       * 'AvailabilityZones'<~Array> - array of strings describing instances currently enabled
        def enable_availability_zones_for_load_balancer(availability_zones, lb_name)
          params = Fog::AWS.indexed_param('AvailabilityZones.member', [*availability_zones])
          request({
            'Action'           => 'EnableAvailabilityZonesForLoadBalancer',
            'LoadBalancerName' => lb_name,
            :parser            => Fog::Parsers::AWS::ELB::EnableAvailabilityZonesForLoadBalancer.new
          }.merge!(params))
        end

        alias_method :enable_zones, :enable_availability_zones_for_load_balancer
      end

      class Mock
        def enable_availability_zones_for_load_balancer(availability_zones, lb_name)
          raise Fog::AWS::ELB::NotFound unless load_balancer = self.data[:load_balancers][lb_name]

          response = Excon::Response.new
          response.status = 200

          load_balancer['AvailabilityZones'] << availability_zones
          load_balancer['AvailabilityZones'].flatten!.uniq!

          response.body = {
            'ResponseMetadata' => {
              'RequestId' => Fog::AWS::Mock.request_id
            },
            'EnableAvailabilityZonesForLoadBalancerResult' => {
              'AvailabilityZones' => load_balancer['AvailabilityZones']
            }
          }

          response
        end

        alias_method :enable_zones, :enable_availability_zones_for_load_balancer
      end
    end
  end
end
