module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/describe_subnets'

        # Describe all or specified subnets
        #
        # ==== Parameters
        # * filters<~Hash> - List of filters to limit results with
        #
        # === Returns
        # * response<~Excon::Response>:
        # * body<~Hash>:
        # * 'requestId'<~String> - Id of request
        # * 'subnetSet'<~Array>:
        #   * 'subnetId'<~String> - The Subnet's ID
        #   * 'state'<~String> - The current state of the Subnet. ['pending', 'available']
        #   * 'vpcId'<~String> - The ID of the VPC the subnet is in
        #   * 'cidrBlock'<~String> - The CIDR block the Subnet covers.
        #   * 'availableIpAddressCount'<~Integer> - The number of unused IP addresses in the subnet (the IP addresses for any
        #     stopped instances are considered unavailable)
        #   * 'availabilityZone'<~String> - The Availability Zone the subnet is in.
        #   * 'tagSet'<~Array>: Tags assigned to the resource.
        #     * 'key'<~String> - Tag's key
        #     * 'value'<~String> - Tag's value
        #   * 'mapPublicIpOnLaunch'<~Boolean> - Indicates whether instances launched in this subnet receive a public IPv4 address.
        #   * 'defaultForAz'<~Boolean> - Indicates whether this is the default subnet for the Availability Zone.
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/2011-07-15/APIReference/index.html?ApiReference-query-DescribeSubnets.html]
        def describe_subnets(filters = {})
          unless filters.is_a?(Hash)
            Fog::Logger.warning("describe_subnets with #{filters.class} param is deprecated, use describe_subnets('subnet-id' => []) instead [light_black](#{caller.first})[/]")
            filters = {'subnet-id' => [*filters]}
          end
          params = Fog::AWS.indexed_filters(filters)
          request({
            'Action'    => 'DescribeSubnets',
            :idempotent => true,
            :parser     => Fog::Parsers::AWS::Compute::DescribeSubnets.new
          }.merge!(params))
        end
      end

      class Mock
        def describe_subnets(filters = {})
          subnets = self.data[:subnets]

          # Transition from pending to available
          subnets.each do |subnet|
            case subnet['state']
              when 'pending'
                subnet['state'] = 'available'
            end
          end

          if filters['subnet-id']
            subnets = subnets.reject {|subnet| subnet['subnetId'] != filters['subnet-id']}
          end

          Excon::Response.new(
            :status => 200,
            :body   => {
              'requestId' => Fog::AWS::Mock.request_id,
              'subnetSet' => subnets
            }
          )
        end
      end
    end
  end
end
