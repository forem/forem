module Fog
  module Parsers
    module AWS
      module ELB
        class DescribeLoadBalancers < Fog::Parsers::Base
          def reset
            reset_load_balancer
            reset_listener_description
            reset_stickiness_policy
            reset_backend_server_description
            @results = { 'LoadBalancerDescriptions' => [] }
            @response = { 'DescribeLoadBalancersResult' => {}, 'ResponseMetadata' => {} }
          end

          def reset_load_balancer
            @load_balancer = { 'Subnets' => [], 'SecurityGroups' => [], 'ListenerDescriptions' => [], 'Instances' => [], 'AvailabilityZones' => [], 'Policies' => {'AppCookieStickinessPolicies' => [], 'LBCookieStickinessPolicies' => [], 'OtherPolicies' => []}, 'HealthCheck' => {}, 'SourceSecurityGroup' => {}, 'BackendServerDescriptions' => [] }
          end

          def reset_listener_description
            @listener_description = { 'PolicyNames' => [], 'Listener' => {} }
          end

          def reset_backend_server_description
            @backend_server_description = {}
          end

          def reset_stickiness_policy
            @stickiness_policy = {}
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'ListenerDescriptions'
              @in_listeners = true
            when 'Instances'
              @in_instances = true
            when 'AvailabilityZones'
              @in_availability_zones = true
            when 'SecurityGroups'
              @in_security_groups = true
            when 'Subnets'
              @in_subnets = true
            when 'PolicyNames'
              @in_policy_names = true
            when 'Policies'
              @in_policies = true
            when 'LBCookieStickinessPolicies'
              @in_lb_cookies = true
            when 'AppCookieStickinessPolicies'
              @in_app_cookies = true
            when 'AppCookieStickinessPolicies'
              @in_app_cookies = true
            when 'OtherPolicies'
              @in_other_policies = true
            when 'BackendServerDescriptions'
              @in_backend_server_descriptions = true
            end
          end

          def end_element(name)
            case name
            when 'member'
              if @in_policy_names && @in_listeners
                @listener_description['PolicyNames'] << value
              elsif @in_availability_zones
                @load_balancer['AvailabilityZones'] << value
              elsif @in_security_groups
                @load_balancer['SecurityGroups'] << value
              elsif @in_subnets
                @load_balancer['Subnets'] << value
              elsif @in_listeners
                @load_balancer['ListenerDescriptions'] << @listener_description
                reset_listener_description
              elsif @in_app_cookies
                @load_balancer['Policies']['AppCookieStickinessPolicies'] << @stickiness_policy
                reset_stickiness_policy
              elsif @in_lb_cookies
                @load_balancer['Policies']['LBCookieStickinessPolicies'] << @stickiness_policy
                reset_stickiness_policy
              elsif @in_other_policies
                @load_balancer['Policies']['OtherPolicies'] << value
              elsif @in_backend_server_descriptions && @in_policy_names
                @backend_server_description['PolicyNames'] ||= []
                @backend_server_description['PolicyNames'] << value
              elsif @in_backend_server_descriptions && !@in_policy_names
                @load_balancer['BackendServerDescriptions'] << @backend_server_description
                reset_backend_server_description
              elsif !@in_instances && !@in_policies && !@in_backend_server_descriptions
                @results['LoadBalancerDescriptions'] << @load_balancer
                reset_load_balancer
              end

            when 'BackendServerDescriptions'
              @in_backend_server_descriptions = false

            when 'InstancePort'
              if @in_backend_server_descriptions
                @backend_server_description[name] = value.to_i
              elsif @in_listeners
                @listener_description['Listener'][name] = value.to_i
              end

            when 'CanonicalHostedZoneName', 'CanonicalHostedZoneNameID', 'LoadBalancerName', 'DNSName', 'Scheme', 'Type', 'State',
                 'LoadBalancerArn', 'IpAddressType', 'CanonicalHostedZoneId'
              @load_balancer[name] = value
            when 'CreatedTime'
              @load_balancer[name] = Time.parse(value)

            when 'ListenerDescriptions'
              @in_listeners = false
            when 'PolicyNames'
              @in_policy_names = false
            when 'Protocol', 'SSLCertificateId', 'InstanceProtocol'
              @listener_description['Listener'][name] = value
            when 'LoadBalancerPort'
              @listener_description['Listener'][name] = value.to_i

            when 'Instances'
              @in_instances = false
            when 'InstanceId'
              @load_balancer['Instances'] << value
            when 'VPCId', 'VpcId'
              @load_balancer[name] = value
            when 'AvailabilityZones'
              @in_availability_zones = false
            when 'SecurityGroups'
              @in_security_groups = false
            when 'Subnets'
              @in_subnets = false

            when 'Policies'
              @in_policies = false
            when 'AppCookieStickinessPolicies'
              @in_app_cookies = false
            when 'LBCookieStickinessPolicies'
              @in_lb_cookies = false
            when 'OtherPolicies'
              @in_other_policies = false

            when 'OwnerAlias', 'GroupName'
              @load_balancer['SourceSecurityGroup'][name] = value

            when 'Interval', 'HealthyThreshold', 'Timeout', 'UnhealthyThreshold'
              @load_balancer['HealthCheck'][name] = value.to_i
            when 'Target'
              @load_balancer['HealthCheck'][name] = value

            when 'PolicyName', 'CookieName'
              @stickiness_policy[name] = value
            when 'CookieExpirationPeriod'
              @stickiness_policy[name] = value.to_i

            when 'RequestId'
              @response['ResponseMetadata'][name] = value

            when 'NextMarker'
              @results['NextMarker'] = value
            when 'DescribeLoadBalancersResponse'
              @response['DescribeLoadBalancersResult'] = @results
            end
          end
        end
      end
    end
  end
end
