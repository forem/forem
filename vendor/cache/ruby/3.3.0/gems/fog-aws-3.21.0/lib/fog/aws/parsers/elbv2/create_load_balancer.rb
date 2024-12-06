module Fog
  module Parsers
    module AWS
      module ELBV2
        class CreateLoadBalancer < Fog::Parsers::Base
          def reset
            reset_load_balancer
            reset_availability_zone
            @load_balancer_addresses = {}
            @state = {}
            @results = { 'LoadBalancers' => [] }
            @response = { 'CreateLoadBalancerResult' => {}, 'ResponseMetadata' => {} }
          end

          def reset_load_balancer
            @load_balancer = { 'SecurityGroups' => [], 'AvailabilityZones' => [] }
          end

          def reset_availability_zone
            @availability_zone = { 'LoadBalancerAddresses' => [] }
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'AvailabilityZones'
              @in_availability_zones = true
            when 'LoadBalancerAddresses'
              @in_load_balancer_addresses = true
            when 'SecurityGroups'
              @in_security_groups = true
            when 'State'
              @in_state = true
            end
          end

          def end_element(name)
            case name
            when 'member'
              if @in_availability_zones && @in_load_balancer_addresses
                @availability_zone['LoadBalancerAddresses'] << @load_balancer_addresses
              elsif @in_availability_zones
                @load_balancer['AvailabilityZones'] << @availability_zone
                reset_availability_zone
              elsif @in_security_groups
                @load_balancer['SecurityGroups'] << value
              else
                @results['LoadBalancers'] << @load_balancer
                reset_load_balancer
              end
            when 'SubnetId', 'ZoneName'
              @availability_zone[name] = value
            when 'IpAddress', 'AllocationId'
              @load_balancer_addresses[name] = value

            when 'CanonicalHostedZoneName', 'CanonicalHostedZoneNameID', 'LoadBalancerName', 'DNSName', 'Scheme', 'Type',
                 'LoadBalancerArn', 'IpAddressType', 'CanonicalHostedZoneId', 'VpcId'
              @load_balancer[name] = value
            when 'CreatedTime'
              @load_balancer[name] = Time.parse(value)

            when 'LoadBalancerAddresses'
              @in_load_balancer_addresses = false
            when 'AvailabilityZones'
              @in_availability_zones = false
            when 'SecurityGroups'
              @in_security_groups = false
            when 'State'
              @in_state = false
              @load_balancer[name] = @state
              @state = {}
            when 'Code'
              @state[name] = value

            when 'RequestId'
              @response['ResponseMetadata'][name] = value

            when 'NextMarker'
              @results['NextMarker'] = value
            when 'CreateLoadBalancerResponse'
              @response['CreateLoadBalancerResult'] = @results
            end
          end
        end
      end
    end
  end
end
