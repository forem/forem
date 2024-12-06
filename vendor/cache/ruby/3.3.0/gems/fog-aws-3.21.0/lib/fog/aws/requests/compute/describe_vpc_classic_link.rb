module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/describe_vpc_classic_link'
        # Describes the ClassicLink status of one or more VPCs.
        #
        # ==== Parameters
        # * options<~Hash>
        #   * vpc_ids<~Array>  - An array of vpc ids to restruct the results to
        #   * filters<~Hash> - Filters to restrict the results to. Recognises is-classic-link-enabled in addition
        #                      to tag-key, tag-value and tag:key
        # === Returns
        # * response<~Excon::Response>:
        # * body<~Hash>:
        # * 'requestId'<~String>           - Id of request
        # * 'vpcSet'<~Array>               - array of VpcClassicLink
        #   * 'vpcId'<~String>
        #   * 'classicLinkEnabled'<~Boolean>
        #   * 'tagSet'<~Hash>
        #
        # (Amazon API Reference)[http://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeVpcClassicLink.html
        def describe_vpc_classic_link(options={})
          params = {}
          params.merge!(Fog::AWS.indexed_param('VpcId', options[:vpc_ids])) if options[:vpc_ids]
          params.merge!(Fog::AWS.indexed_filters(options[:filters])) if options[:filters]
          request({
            'Action'    => 'DescribeVpcClassicLink',
            :parser     => Fog::Parsers::AWS::Compute::DescribeVpcClassicLink.new
          }.merge(params))
        end
      end

      class Mock
        def describe_vpc_classic_link(options={})
          response = Excon::Response.new
          vpcs = self.data[:vpcs]
          if vpc_ids = options[:vpc_ids]
            vpcs = vpc_ids.collect do |vpc_id|
              vpc = vpcs.find{ |v| v['vpcId'] == vpc_id }
              raise Fog::AWS::Compute::NotFound.new("The VPC '#{vpc_id}' does not exist") unless vpc
              vpc
            end
          end
          vpcs = apply_tag_filters(vpcs, options[:filters], 'vpcId') if options[:filters]

          response.status = 200
          vpc_data = vpcs.collect do |vpc|
            {
              'vpcId' => vpc['vpcId'],
              'classicLinkEnabled' => vpc['classicLinkEnabled'],
              'tagSet' => self.data[:tag_sets][vpc['vpcId']] || {}
            }
          end
          response.body = {
            'requestId' => Fog::AWS::Mock.request_id,
            'vpcSet' => vpc_data
          }
          response
        end
      end
    end
  end
end
