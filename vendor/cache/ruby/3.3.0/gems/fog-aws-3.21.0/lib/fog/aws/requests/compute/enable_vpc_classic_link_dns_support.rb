module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/basic'

        # Enables a VPC to support DNS hostname resolution for ClassicLink
        #
        # ==== Parameters
        # * vpc_id<~String> - The ID of the ClassicLink-enabled VPC.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - Id of the request
        #     * 'return'<~Boolean>   - Whether the request succeeded
        #
        # http://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_EnableVpcClassicLinkDnsSupport.html

        def enable_vpc_classic_link_dns_support(vpc_id)
          request(
            'Action' => 'EnableVpcClassicLinkDnsSupport',
            'VpcId'  => vpc_id,
            :parser  => Fog::Parsers::AWS::Compute::Basic.new
          )
        end
      end

      class Mock
        def enable_vpc_classic_link_dns_support(vpc_id)
          response = Excon::Response.new
          unless vpc = self.data[:vpcs].find { |v| v['vpcId'] == vpc_id }
            raise Fog::AWS::Compute::NotFound.new("The VPC '#{vpc_id}' does not exist")
          end
          vpc['classicLinkDnsSupport'] = true
          response.body = {
            'requestId' => Fog::AWS::Mock.request_id,
            'return'    => true
          }
          response
        end
      end
    end
  end
end
