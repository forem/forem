module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/describe_vpcs'

        # Describe all or specified vpcs
        #
        # ==== Parameters
        # * filters<~Hash> - List of filters to limit results with
        #
        # === Returns
        # * response<~Excon::Response>:
        # * body<~Hash>:
        # * 'requestId'<~String> - Id of request
        # * 'vpcSet'<~Array>:
        # * 'vpcId'<~String> - The VPC's ID
        # * 'state'<~String> - The current state of the VPC. ['pending', 'available']
        # * 'cidrBlock'<~String> - The CIDR block the VPC covers.
        # * 'dhcpOptionsId'<~String> - The ID of the set of DHCP options.
        # * 'tagSet'<~Array>: Tags assigned to the resource.
        # * 'key'<~String> - Tag's key
        # * 'value'<~String> - Tag's value
        # * 'instanceTenancy'<~String> - The allowed tenancy of instances launched into the VPC.
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/2011-07-15/APIReference/index.html?ApiReference-query-DescribeVpcs.html]
        def describe_vpcs(filters = {})
          unless filters.is_a?(Hash)
            Fog::Logger.warning("describe_vpcs with #{filters.class} param is deprecated, use describe_vpcs('vpc-id' => []) instead [light_black](#{caller.first})[/]")
            filters = {'vpc-id' => [*filters]}
          end
          params = Fog::AWS.indexed_filters(filters)
          request({
            'Action' => 'DescribeVpcs',
            :idempotent => true,
            :parser => Fog::Parsers::AWS::Compute::DescribeVpcs.new
          }.merge!(params))
        end
      end

      class Mock
        def describe_vpcs(filters = {})
          vpcs = self.data[:vpcs]
          vpcs = apply_tag_filters(vpcs, filters, 'vpcId')

          # Transition from pending to available
          vpcs.each do |vpc|
            case vpc['state']
              when 'pending'
                vpc['state'] = 'available'
            end
          end

          if filters['vpc-id']
            vpcs = vpcs.reject {|vpc| vpc['vpcId'] != filters['vpc-id']}
          end

          vpcs.each do |vpc|
            tags = self.data[:tag_sets][vpc['vpcId']]
            vpc.merge!('tagSet' => tags) if tags
          end

          Excon::Response.new(
            :status => 200,
            :body   => {
              'requestId' => Fog::AWS::Mock.request_id,
              'vpcSet'    => vpcs
            }
          )
        end
      end
    end
  end
end
