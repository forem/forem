module Fog
  module AWS
    class ELBV2
      class Real
        require 'fog/aws/parsers/elbv2/describe_load_balancers'

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
        #       * 'LoadBalancers'<~Array>
        #         * 'AvailabilityZones'<~Array>:
        #           * 'SubnetId'<~String> - ID of the subnet
        #           * 'ZoneName'<~String> - Name of the Availability Zone
        #           * 'LoadBalancerAddresses'<~Array>:
        #             * 'IpAddress'<~String> - IP address
        #             * 'AllocationId'<~String> - ID of the AWS allocation
        #         * 'CanonicalHostedZoneName'<~String> - name of the Route 53 hosted zone associated with the load balancer
        #         * 'CanonicalHostedZoneNameID'<~String> - ID of the Route 53 hosted zone associated with the load balancer
        #         * 'CreatedTime'<~Time> - time load balancer was created
        #         * 'DNSName'<~String> - external DNS name of load balancer
        #         * 'LoadBalancerName'<~String> - name of load balancer
        #         * 'SecurityGroups'<~Array> - array of security group id
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
            :parser   => Fog::Parsers::AWS::ELBV2::DescribeLoadBalancers.new
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
              lb = self.data[:load_balancers_v2].find { |name, data| name == lb_name }
              raise Fog::AWS::ELBV2::NotFound unless lb
              lb[1].dup
            end.compact
          else
            self.data[:load_balancers_v2].map { |lb, values| values.dup }
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
              'LoadBalancers' => load_balancers
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
