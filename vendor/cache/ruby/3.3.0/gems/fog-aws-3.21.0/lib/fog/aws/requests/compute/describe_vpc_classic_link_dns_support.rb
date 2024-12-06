module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/describe_vpc_classic_link_dns_support'

        # escribes the ClassicLink DNS support status of one or more VPCs
        #
        # ==== Parameters
        # * options<~Hash>
        #   * vpc_ids<~Array> - An array of vpc ids to restrict results to
        #   * 'MaxResults'    - Maximum number of items to return
        #   * 'NextToken'     - The token for the next set of items to return
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - Id of the request
        #     * 'vpcs'<~Array>       - Information about the ClassicLink DNS support status of the VPCs
        #       * 'vpcId'<~String>
        #       * 'classicLinkDnsSupported'<~Boolean>
        #
        # http://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeVpcClassicLinkDnsSupport.html

        def describe_vpc_classic_link_dns_support(options={})
          params = {}
          params.merge!(Fog::AWS.indexed_param('VpcIds', options[:vpc_ids])) if options[:vpc_ids]
          request({
            'Action'     => 'DescribeVpcClassicLinkDnsSupport',
            'MaxResults' => options['MaxResults'],
            'NextToken'  => options['NextToken'],
            :parser      => Fog::Parsers::AWS::Compute::DescribeVpcClassicLinkDnsSupport.new
          }.merge(params))
        end
      end

      class Mock
        def describe_vpc_classic_link_dns_support(options={})
          response = Excon::Response.new

          vpcs = self.data[:vpcs]

          if options[:vpc_ids]
            vpcs = vpcs.select { |v| options[:vpc_ids].include?(v['vpcId']) }
          end

          response.body = {'vpcs' => vpcs.map { |v| {"vpcId" => v['vpcId'], "classicLinkDnsSupported" => v['classicLinkDnsSupport']} } }
          response
        end
      end
    end
  end
end
