module Fog
  module AWS
    class ELBV2
      class Real
        require 'fog/aws/parsers/elbv2/create_load_balancer'

        # Create a new Elastic Load Balancer
        #
        # ==== Parameters
        # * name<~String> - The name of the load balancer.
        #                   This name must be unique per region per account, can have a maximum of 32 characters, must contain only alphanumeric characters or hyphens,
        #                   must not begin or end with a hyphen, and must not begin with "internal-".
        #                 - Required: Yes
        # * options<~Hash>:
        #   * ip_address_type<~String> - [Application Load Balancers] The type of IP addresses used by the subnets for your load balancer.
        #                                The possible values are ipv4 (for IPv4 addresses) and dualstack (for IPv4 and IPv6 addresses).
        #                                Internal load balancers must use ipv4.
        #                              - Required: No
        #   * scheme<~String> - The default is an Internet-facing load balancer. Valid Values: internet-facing | internal
        #                     - Required: No
        #   * security_groups<~Array> - The IDs of the security groups for the load balancer.
        #                             - Required: No
        #   * subnet_mappings<~Array> - The IDs of the public subnets. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.
        #                             - [Application Load Balancers] You must specify subnets from at least two Availability Zones.
        #                               You cannot specify Elastic IP addresses for your subnets.
        #                             - [Network Load Balancers] You can specify subnets from one or more Availability Zones.
        #                               You can specify one Elastic IP address per subnet if you need static IP addresses for your internet-facing load balancer.
        #                               For internal load balancers, you can specify one private IP address per subnet from the IPv4 range of the subnet.
        #                             - Required: No
        #   * subnets<~Array> - The IDs of the public subnets. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.
        #                     - [Application Load Balancers] You must specify subnets from at least two Availability Zones.
        #                     - [Network Load Balancers] You can specify subnets from one or more Availability Zones.
        #                     - Required: No
        #   * tags<~Hash> - One or more tags to assign to the load balancer.
        #                 - Required: No
        #   * type<~String> - The type of load balancer. The default is application. Valid Values: application | network
        #                   - Required: No
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        #     * 'CreateLoadBalancerResult'<~Hash>:
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
        def create_load_balancer(name, options = {})
          params = {}
          params.merge!(Fog::AWS.indexed_param('Subnets.member.%d', options[:subnets]))
          params.merge!(Fog::AWS.indexed_param('SecurityGroups.member.%d', options[:security_groups]))
          params.merge!(Fog::AWS.serialize_keys('Scheme', options[:scheme]))
          params.merge!(Fog::AWS.serialize_keys('Type', options[:type]))
          params.merge!(Fog::AWS.serialize_keys('IpAddressType', options[:ip_address_type]))


          unless options[:tags].nil?
            tag_keys   = options[:tags].keys.sort
            tag_values = tag_keys.map { |key| options[:tags][key] }
            params.merge!(Fog::AWS.indexed_param('Tags.member.%d.Key', tag_keys))
            params.merge!(Fog::AWS.indexed_param('Tags.member.%d.Value', tag_values))
          end

          unless options[:subnet_mappings].nil?
            subnet_ids = []
            allocation_ids = []
            private_ipv4_address = []
            options[:subnet_mappings].each do |subnet_mapping|
              subnet_ids.push(subnet_mapping[:subnet_id])
              allocation_ids.push(subnet_mapping[:allocation_id])
              private_ipv4_address.push(subnet_mapping[:private_ipv4_address])
            end
            params.merge!(Fog::AWS.indexed_param('SubnetMappings.member.%d.SubnetId', subnet_ids))
            params.merge!(Fog::AWS.indexed_param('SubnetMappings.member.%d.AllocationId', allocation_ids))
            params.merge!(Fog::AWS.indexed_param('SubnetMappings.member.%d.PrivateIPv4Address', private_ipv4_address))
          end


          request({
            'Action'           => 'CreateLoadBalancer',
            'Name' => name,
            :parser            => Fog::Parsers::AWS::ELBV2::CreateLoadBalancer.new
          }.merge!(params))
        end
      end

      class Mock
        def create_load_balancer(name, options = {})
          response = Excon::Response.new
          response.status = 200

          raise Fog::AWS::ELBV2::IdentifierTaken if self.data[:load_balancers_v2].key? name

          dns_name = Fog::AWS::ELBV2::Mock.dns_name(name, @region)
          type = options[:type] || 'application'
          load_balancer_arn = Fog::AWS::Mock.arn('elasticloadbalancing', self.data[:owner_id], "loadbalancer/#{type[0..2]}/#{name}/#{Fog::AWS::Mock.key_id}")

          subnet_ids = options[:subnets] || []
          region = if subnet_ids.any?
                     # using Hash here for Rubt 1.8.7 support.
                     Hash[
                       Fog::AWS::Compute::Mock.data.select do |_, region_data|
                         unless region_data[@aws_access_key_id].nil?
                           region_data[@aws_access_key_id][:subnets].any? do |region_subnets|
                             subnet_ids.include? region_subnets['subnetId']
                           end
                         end
                       end
                     ].keys[0]
                   else
                     'us-east-1'
                   end

          subnets = Fog::AWS::Compute::Mock.data[region][@aws_access_key_id][:subnets].select {|e| subnet_ids.include?(e["subnetId"]) }
          availability_zones = subnets.map do |subnet|
            { "LoadBalancerAddresses"=>[], "SubnetId"=>subnet["subnetId"], "ZoneName"=>subnet["availabilityZone"]}
          end
          vpc_id = subnets.first['vpcId']

          self.data[:tags] ||= {}
          self.data[:tags][load_balancer_arn] = options[:tags] || {}

          load_balancer = {
            'AvailabilityZones' => availability_zones || [],
            'Scheme' => options[:scheme] || 'internet-facing',
            'SecurityGroups' => options[:security_groups] || [],
            'CanonicalHostedZoneId' => '',
            'CreatedTime' => Time.now,
            'DNSName' => dns_name,
            'VpcId' => vpc_id,
            'Type' => type,
            'State' => {'Code' => 'provisioning'},
            'LoadBalancerArn' => load_balancer_arn,
            'LoadBalancerName' => name
          }
          self.data[:load_balancers_v2][load_balancer_arn] = load_balancer
          response.body = {
            'ResponseMetadata' => {
              'RequestId' => Fog::AWS::Mock.request_id
            },
            'CreateLoadBalancerResult' => {
              'LoadBalancers' => [load_balancer]
            }
          }

          response
        end
      end
    end
  end
end
