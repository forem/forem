module Fog
  module AWS
    class ELB
      class Real
        require 'fog/aws/parsers/elb/describe_load_balancers'

        # Describe all or specified load balancers
        #
        # ==== Parameters
        # * options<~Hash>
        #   * 'LoadBalancerNames'<~Array> - List of load balancer names to describe, defaults to all
        #   * 'Marker'<String> - Indicates where to begin in your list of load balancers
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        #     * 'DescribeLoadBalancersResult'<~Hash>:
        #       * 'LoadBalancerDescriptions'<~Array>
        #         * 'AvailabilityZones'<~Array> - list of availability zones covered by this load balancer
        #         * 'BackendServerDescriptions'<~Array>:
        #           * 'InstancePort'<~Integer> - the port on which the back-end server is listening
        #           * 'PolicyNames'<~Array> - list of policy names enabled for the back-end server
        #         * 'CanonicalHostedZoneName'<~String> - name of the Route 53 hosted zone associated with the load balancer
        #         * 'CanonicalHostedZoneNameID'<~String> - ID of the Route 53 hosted zone associated with the load balancer
        #         * 'CreatedTime'<~Time> - time load balancer was created
        #         * 'DNSName'<~String> - external DNS name of load balancer
        #         * 'HealthCheck'<~Hash>:
        #           * 'HealthyThreshold'<~Integer> - number of consecutive health probe successes required before moving the instance to the Healthy state
        #           * 'Timeout'<~Integer> - number of seconds after which no response means a failed health probe
        #           * 'Interval'<~Integer> - interval (in seconds) between health checks of an individual instance
        #           * 'UnhealthyThreshold'<~Integer> - number of consecutive health probe failures that move the instance to the unhealthy state
        #           * 'Target'<~String> - string describing protocol type, port and URL to check
        #         * 'Instances'<~Array> - list of instances that the load balancer balances between
        #         * 'ListenerDescriptions'<~Array>
        #           * 'PolicyNames'<~Array> - list of policies enabled
        #           * 'Listener'<~Hash>:
        #             * 'InstancePort'<~Integer> - port on instance that requests are sent to
        #             * 'Protocol'<~String> - transport protocol used for routing in [TCP, HTTP]
        #             * 'LoadBalancerPort'<~Integer> - port that load balancer listens on for requests
        #         * 'LoadBalancerName'<~String> - name of load balancer
        #         * 'Policies'<~Hash>:
        #           * 'LBCookieStickinessPolicies'<~Array> - list of Load Balancer Generated Cookie Stickiness policies for the LoadBalancer
        #           * 'AppCookieStickinessPolicies'<~Array> - list of Application Generated Cookie Stickiness policies for the LoadBalancer
        #           * 'OtherPolicies'<~Array> - list of policy names other than the stickiness policies
        #         * 'SourceSecurityGroup'<~Hash>:
        #           * 'GroupName'<~String> - Name of the source security group to use with inbound security group rules
        #           * 'OwnerAlias'<~String> - Owner of the source security group
        #         * 'NextMarker'<~String> - Marker to specify for next page
        def describe_load_balancers(options = {})
          unless options.is_a?(Hash)
            Fog::Logger.deprecation("describe_load_balancers with #{options.class} is deprecated, use all('LoadBalancerNames' => []) instead [light_black](#{caller.first})[/]")
            options = { 'LoadBalancerNames' => [options].flatten }
          end

          if names = options.delete('LoadBalancerNames')
            options.update(Fog::AWS.indexed_param('LoadBalancerNames.member', [*names]))
          end

          request({
            'Action'  => 'DescribeLoadBalancers',
            :parser   => Fog::Parsers::AWS::ELB::DescribeLoadBalancers.new
          }.merge!(options))
        end
      end

      class Mock
        def describe_load_balancers(options = {})
          unless options.is_a?(Hash)
            Fog::Logger.deprecation("describe_load_balancers with #{options.class} is deprecated, use all('LoadBalancerNames' => []) instead [light_black](#{caller.first})[/]")
            options = { 'LoadBalancerNames' => [options].flatten }
          end

          lb_names = options['LoadBalancerNames'] || []

          lb_names = [*lb_names]
          load_balancers = if lb_names.any?
            lb_names.map do |lb_name|
              lb = self.data[:load_balancers].find { |name, data| name == lb_name }
              raise Fog::AWS::ELB::NotFound unless lb
              lb[1].dup
            end.compact
          else
            self.data[:load_balancers].map { |lb, values| values.dup }
          end

          marker = options.fetch('Marker', 0).to_i
          if load_balancers.count - marker > 400
            next_marker = marker + 400
            load_balancers = load_balancers[marker...next_marker]
          else
            next_marker = nil
          end

          response = Excon::Response.new
          response.status = 200

          response.body = {
            'ResponseMetadata' => {
              'RequestId' => Fog::AWS::Mock.request_id
            },
            'DescribeLoadBalancersResult' => {
              'LoadBalancerDescriptions' => load_balancers.map do |lb|
                lb['Instances'] = lb['Instances'].map { |i| i['InstanceId'] }
                lb['Policies'] = lb['Policies']['Proper'].reduce({'AppCookieStickinessPolicies' => [], 'LBCookieStickinessPolicies' => [], 'OtherPolicies' => []}) { |m, policy|
                  case policy['PolicyTypeName']
                  when 'AppCookieStickinessPolicyType'
                    cookie_name = policy['PolicyAttributeDescriptions'].find{|h| h['AttributeName'] == 'CookieName'}['AttributeValue']
                    m['AppCookieStickinessPolicies'] << { 'PolicyName' => policy['PolicyName'], 'CookieName' => cookie_name }
                  when 'LBCookieStickinessPolicyType'
                    cookie_expiration_period = policy['PolicyAttributeDescriptions'].find{|h| h['AttributeName'] == 'CookieExpirationPeriod'}['AttributeValue'].to_i
                    lb_policy = { 'PolicyName' => policy['PolicyName'] }
                    lb_policy['CookieExpirationPeriod'] = cookie_expiration_period if cookie_expiration_period > 0
                    m['LBCookieStickinessPolicies'] << lb_policy
                  else
                    m['OtherPolicies'] << policy['PolicyName']
                  end
                  m
                }

                lb['BackendServerDescriptions'] = lb.delete('BackendServerDescriptionsRemote')
                lb
              end
            }
          }

          if next_marker
            response.body['DescribeLoadBalancersResult']['NextMarker'] = next_marker.to_s
          end

          response
        end
      end
    end
  end
end
