module Fog
  module Parsers
    module AWS
      module ELB
        class DescribeLoadBalancerAttributes < Fog::Parsers::Base
          def reset
            @response = { 'DescribeLoadBalancerAttributesResult' => { 'LoadBalancerAttributes' => {} }, 'ResponseMetadata' => {} }
            @stack = []
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'ConnectionDraining'
              @connection_draining = {}
            when 'CrossZoneLoadBalancing'
              @cross_zone_load_balancing = {}
            when 'ConnectionSettings'
              @connection_settings = {}
            end
          end

          def end_element(name)
            case name
            when 'Enabled'
              if @cross_zone_load_balancing
                @cross_zone_load_balancing['Enabled'] = value == 'true' ? true : false
              elsif @connection_draining
                @connection_draining['Enabled'] = value == 'true' ? true : false
              end
            when 'IdleTimeout'
              @connection_settings['IdleTimeout'] = value.to_i
            when 'Timeout'
              if @connection_draining
                @connection_draining['Timeout'] = value.to_i
              end
            when 'ConnectionDraining'
              @response['DescribeLoadBalancerAttributesResult']['LoadBalancerAttributes']['ConnectionDraining'] = @connection_draining
              @connection_draining = nil
            when 'CrossZoneLoadBalancing'
              @response['DescribeLoadBalancerAttributesResult']['LoadBalancerAttributes']['CrossZoneLoadBalancing'] = @cross_zone_load_balancing
              @cross_zone_load_balancing = nil
            when 'ConnectionSettings'
              @response['DescribeLoadBalancerAttributesResult']['LoadBalancerAttributes']['ConnectionSettings'] = @connection_settings
              @connection_settings = nil
            when 'RequestId'
              @response['ResponseMetadata'][name] = value
            end
          end
        end
      end
    end
  end
end
